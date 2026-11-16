"""TC-FAM-04 HU-05: two REAL connections/overlapping transactions, not mocks."""
import base64
from concurrent.futures import ThreadPoolExecutor
import json
import os
import subprocess
import threading
import time
import uuid
from local_supabase import LocalSupabase


def main():
    results=[]
    with LocalSupabase() as db:
        actors=[db.actor('Admin Concurrente Uno'),db.actor('Admin Concurrente Dos')]
        for operation,isolation in [('leave','READ COMMITTED'),('demote','READ COMMITTED'),('demote','REPEATABLE READ')]:
            family=db.family(actors[0],'Familia Concurrente Ficticia')
            status,invite=db.rpc('invite_member',{'p_family_id':family['id'],'p_target_public_id':actors[1]['public_id'],'p_request_id':str(uuid.uuid4())},actors[0]);assert status==200
            status,_=db.rpc('respond_invitation',{'p_invitation_id':invite['id'],'p_decision':'accept','p_request_id':str(uuid.uuid4())},actors[1]);assert status==200
            status,_=db.rpc('set_member_admin',{'p_family_id':family['id'],'p_target_user_id':actors[1]['user_id'],'p_is_admin':True},actors[0]);assert status==200
            processes=[]
            try:
                for index,actor in enumerate(actors):
                    process=subprocess.Popen([os.environ.get('DOCKER_BIN','docker'),'exec','-i','supabase_db_nido','psql','-X','-q','-A','-t','-U','postgres','-d','postgres','-v','ON_ERROR_STOP=1'],stdin=subprocess.PIPE,stdout=subprocess.PIPE,stderr=subprocess.PIPE,text=True,bufsize=1)
                    processes.append(process)
                    encoded=actor['token'].split('.')[1]
                    claims=json.loads(base64.urlsafe_b64decode(encoded+'='*(-len(encoded)%4)))
                    # Claims are from local Auth; SQL tests validate authorization,
                    # not JWT signatures (HTTP tests cover the real gateway).
                    literal=json.dumps(claims).replace("'","''")
                    process.stdin.write(f"begin isolation level {isolation}; set application_name='nido_concurrency_{index}'; set local role authenticated; select set_config('request.jwt.claims','{literal}',true); select 'READY';\n")
                    process.stdin.flush()
                    for _ in range(10):
                        line=process.stdout.readline()
                        if line.strip()=='READY':
                            break
                        assert line,'Concurrent connection failed before ready'
                    else:
                        raise AssertionError('Concurrent connection not ready')
                barrier=threading.Barrier(2)
                def mutate(index):
                    fid=str(uuid.UUID(family['id']))
                    call=f"public.leave_family('{fid}')" if operation=='leave' else f"public.set_member_admin('{fid}',auth.uid(),false)"
                    barrier.wait(timeout=10)
                    _,error=processes[index].communicate(f'select {call}; select pg_sleep(2); commit;\n',timeout=20)
                    return processes[index].returncode,error
                observed=False
                with ThreadPoolExecutor(max_workers=2) as pool:
                    futures=[pool.submit(mutate,index) for index in range(2)]
                    for _ in range(10):
                        waiting=int(db.sql("select count(*) from pg_stat_activity where application_name like 'nido_concurrency_%' and wait_event_type='Lock';"))
                        if waiting:
                            observed=True
                            break
                        if all(future.done() for future in futures):
                            break
                        time.sleep(0.05)
                    completed=[future.result() for future in futures]
                assert observed,'Transactions did not demonstrate overlapping row-lock contention'
                assert sorted(code==0 for code,_ in completed)==[False,True],'Exactly one admin mutation must commit'
                error=next(error for code,error in completed if code!=0)
                assert ('last_admin' in error) if isolation=='READ COMMITTED' else ('could not serialize' in error),'Unexpected conflict result'
                fid=str(uuid.UUID(family['id']))
                remaining=int(db.sql(f"select count(*) from public.memberships where family_id='{fid}' and active and is_admin;"))
                assert remaining==1,'Last-admin invariant violated'
                results.append({'case':'TC-FAM-04','operation':operation,'isolation':isolation,'connections':2,'observed_lock_wait':True,'committed':1,'rejected':1,'remaining_admins':remaining})
            finally:
                for process in processes:
                    if process.poll() is None:
                        process.kill()
                        process.wait(timeout=5)
    print(json.dumps({'status':'PASS','scenarios':results},indent=2))


if __name__=='__main__':
    main()
