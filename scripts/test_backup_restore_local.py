"""OPS-01: real local pg_dump/restore with synthetic data and restored RLS.

The dump is sensitive, even for tests. It is written only beneath the ignored
evidence directory. This validates DB restoration, not Storage object backups,
cloud-provider snapshots or recovery on another cluster/key configuration.
"""
import argparse
import base64
from datetime import datetime,timezone
import hashlib
import json
import os
import re
import subprocess
import uuid
from local_supabase import LocalSupabase,ROOT


def main():
    parser=argparse.ArgumentParser();parser.add_argument('--run-id',required=True);args=parser.parse_args()
    assert re.fullmatch(r'[A-Za-z0-9_-]+',args.run_id)
    folder=ROOT/'evidencias/ejecuciones'/args.run_id;folder.mkdir(parents=True,exist_ok=False)
    dump_path=folder/'synthetic-private.dump'
    restored='nido_restore_'+uuid.uuid4().hex[:8]
    assert re.fullmatch(r'nido_restore_[0-9a-f]{8}',restored)
    docker=os.environ.get('DOCKER_BIN','docker')
    report={'started_utc':datetime.now(timezone.utc).isoformat(),'commit':subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip(),'environment':'Supabase LOCAL PostgreSQL / synthetic','storage_bytes_tested':False,'status':'FAIL'}
    created=False
    with LocalSupabase() as db:
        try:
            actor=db.actor('Persona Backup Uno');peer=db.actor('Persona Backup Dos');family=db.family(actor,'Grupo Backup Ficticio')
            status,invite=db.rpc('invite_member',{'p_family_id':family['id'],'p_target_public_id':peer['public_id'],'p_request_id':str(uuid.uuid4())},actor);assert status==200
            status,_=db.rpc('respond_invitation',{'p_invitation_id':invite['id'],'p_decision':'accept','p_request_id':str(uuid.uuid4())},peer);assert status==200
            status,_=db.rpc('save_pet',{'p_family_id':family['id'],'p_pet_id':None,'p_name':'Mascota Backup','p_species':'Gato','p_birth_date':None,'p_notes':'Ficticio','p_expected_version':None,'p_request_id':str(uuid.uuid4())},actor);assert status==200
            # Exclude orchestration schemas/extensions. Recreate cron/network
            # dispatch from the operational playbook, never replay live jobs.
            with dump_path.open('wb') as output:
                result=subprocess.run([docker,'exec','supabase_db_nido','pg_dump','-U','postgres','-Fc','--exclude-schema=cron','--exclude-schema=net','--exclude-extension=pg_cron','--exclude-extension=pg_net','postgres'],stdout=output,stderr=subprocess.PIPE)
            assert result.returncode==0,'Local dump failed'
            subprocess.run([docker,'exec','supabase_db_nido','createdb','-U','postgres',restored],capture_output=True,check=True);created=True
            with dump_path.open('rb') as source:
                result=subprocess.run([docker,'exec','-i','supabase_db_nido','pg_restore','-U','supabase_admin','--exit-on-error','--dbname',restored],stdin=source,capture_output=True)
            if result.returncode!=0:
                (folder/'restore.error').write_bytes(result.stderr)
                raise AssertionError('Restore failed; inspect ignored local restore.error')
            encoded=actor['token'].split('.')[1];claims=json.loads(base64.urlsafe_b64decode(encoded+'='*(-len(encoded)%4)));literal=json.dumps(claims).replace("'","''")
            aid=str(uuid.UUID(actor['user_id']));pid=str(uuid.UUID(peer['user_id']));fid=str(uuid.UUID(family['id']))
            sql=f"begin;set local role authenticated;select set_config('request.jwt.claims','{literal}',true);select json_build_object('live_session',private.has_live_session(),'own_private',(select count(*) from public.private_profiles where user_id='{aid}'),'peer_private',(select count(*) from public.private_profiles where user_id='{pid}'),'members',(select count(*) from public.memberships where family_id='{fid}'),'pets',(select count(*) from public.pets where family_id='{fid}'),'admin',private.is_family_admin('{fid}'));rollback;"
            result=subprocess.run([docker,'exec','-i','supabase_db_nido','psql','-X','-q','-A','-t','-U','postgres','-d',restored,'-v','ON_ERROR_STOP=1'],input=sql,text=True,capture_output=True,check=True)
            checks=json.loads(result.stdout.strip().splitlines()[-1])
            assert checks=={'live_session':True,'own_private':1,'peer_private':0,'members':2,'pets':1,'admin':True},'Restored data/RLS mismatch'
            report.update({'status':'PASS','checks':checks,'dump_sha256':hashlib.sha256(dump_path.read_bytes()).hexdigest(),'dump_bytes':dump_path.stat().st_size,'restore_role':'supabase_admin (local only)','assertion_role':'authenticated','preserved_owners_and_acl':True,'excluded_orchestration':['cron','net','pg_cron','pg_net']})
        finally:
            if created:
                # Generated/validated disposable database only; never postgres.
                subprocess.run([docker,'exec','supabase_db_nido','dropdb','-U','postgres',restored],capture_output=True,check=True)
            report['finished_utc']=datetime.now(timezone.utc).isoformat()
            (folder/'report.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf-8')
    print(json.dumps({'status':report['status'],'evidence':str(folder),'storage_bytes_tested':False}))


if __name__=='__main__':
    main()
