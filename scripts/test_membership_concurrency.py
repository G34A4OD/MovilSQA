"""TC-FAM-04 HU-05: two real connections and overlapping transactions."""
import json
import uuid
from local_supabase import LocalSupabase
from local_concurrency import race_transactions


def main():
    results=[]
    with LocalSupabase() as db:
        actors=[db.actor('Admin Concurrente Uno'),db.actor('Admin Concurrente Dos')]
        for operation,isolation in [('leave','READ COMMITTED'),('demote','READ COMMITTED'),('demote','REPEATABLE READ')]:
            family=db.family(actors[0],'Familia Concurrente Ficticia')
            status,invite=db.rpc('invite_member',{'p_family_id':family['id'],'p_target_public_id':actors[1]['public_id'],'p_request_id':str(uuid.uuid4())},actors[0]);assert status==200
            status,_=db.rpc('respond_invitation',{'p_invitation_id':invite['id'],'p_decision':'accept','p_request_id':str(uuid.uuid4())},actors[1]);assert status==200
            status,_=db.rpc('set_member_admin',{'p_family_id':family['id'],'p_target_user_id':actors[1]['user_id'],'p_is_admin':True},actors[0]);assert status==200
            fid=str(uuid.UUID(family['id']))
            statement=f"select public.leave_family('{fid}')" if operation=='leave' else f"select public.set_member_admin('{fid}',auth.uid(),false)"
            completed=race_transactions(db,actors,[statement,statement],isolation)
            assert sorted(code==0 for code,_ in completed)==[False,True],'Exactly one admin mutation must commit'
            error=next(error for code,error in completed if code!=0)
            assert ('last_admin' in error) if isolation=='READ COMMITTED' else ('could not serialize' in error),'Unexpected conflict result'
            remaining=int(db.sql(f"select count(*) from public.memberships where family_id='{fid}' and active and is_admin;"))
            assert remaining==1,'Last-admin invariant violated'
            results.append({'case':'TC-FAM-04','operation':operation,'isolation':isolation,'connections':2,'observed_lock_wait':True,'committed':1,'rejected':1,'remaining_admins':remaining})
    print(json.dumps({'status':'PASS','scenarios':results},indent=2))


if __name__=='__main__':
    main()
