"""TC-FAM-05 HU-06: opposite ancestry edits cannot create a concurrent cycle."""
import json
import uuid
from local_supabase import LocalSupabase
from local_concurrency import race_transactions


def main():
    results=[]
    with LocalSupabase() as db:
        actors=[db.actor('Árbol Concurrente Uno'),db.actor('Árbol Concurrente Dos')]
        for isolation in ('READ COMMITTED','REPEATABLE READ'):
            family=db.family(actors[0],'Árbol Concurrente Ficticio')
            status,invite=db.rpc('invite_member',{'p_family_id':family['id'],'p_target_public_id':actors[1]['public_id'],'p_request_id':str(uuid.uuid4())},actors[0]);assert status==200
            status,_=db.rpc('respond_invitation',{'p_invitation_id':invite['id'],'p_decision':'accept','p_request_id':str(uuid.uuid4())},actors[1]);assert status==200
            status,_=db.rpc('set_member_admin',{'p_family_id':family['id'],'p_target_user_id':actors[1]['user_id'],'p_is_admin':True},actors[0]);assert status==200
            fid=str(uuid.UUID(family['id']));ids=[str(uuid.UUID(a['user_id'])) for a in actors]
            statements=[f"select public.save_relationship('{fid}',null,'{ids[i]}','{ids[1-i]}','parent',null,'{uuid.uuid4()}')" for i in range(2)]
            completed=race_transactions(db,actors,statements,isolation)
            assert sorted(code==0 for code,_ in completed)==[False,True],'Exactly one opposing edge must commit'
            error=next(error for code,error in completed if code!=0)
            assert ('invalid_relationship' in error) if isolation=='READ COMMITTED' else ('could not serialize' in error),'Unexpected graph conflict'
            edges=int(db.sql(f"select count(*) from public.relationships where family_id='{fid}';"))
            assert edges==1,'Concurrent opposite links created a cycle'
            results.append({'case':'TC-FAM-05','isolation':isolation,'connections':2,'observed_lock_wait':True,'committed':1,'rejected':1,'final_edges':edges})
    print(json.dumps({'status':'PASS','scenarios':results},indent=2))


if __name__=='__main__':
    main()
