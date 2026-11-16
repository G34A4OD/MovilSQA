"""OPS-01 / Gerardo smoke on real Android, LOCAL Supabase and synthetic mail.

No cloud credentials. User JWT/passwords stay in memory or ignored local defines.
The device ends signed out; after this test rebuild/install lib/main.dart with
the normal cloud config so the phone does not retain an integration-test target.
"""
import argparse
from datetime import datetime, timezone
import hashlib
import html
import json
import os
from pathlib import Path
import re
import secrets
import shlex
import subprocess
import threading
import time
import urllib.error
import urllib.parse
import urllib.request
import uuid
from local_supabase import LocalSupabase, ROOT


class NoRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self,*args):
        return None


def main():
    parser=argparse.ArgumentParser()
    parser.add_argument('--device',required=True)
    parser.add_argument('--flutter',required=True)
    parser.add_argument('--adb',required=True)
    parser.add_argument('--run-id',required=True)
    args=parser.parse_args()
    assert re.fullmatch(r'[A-Za-z0-9_-]+',args.run_id),'Invalid run id'
    output=ROOT/'evidencias/ejecuciones'/args.run_id
    output.mkdir(parents=True,exist_ok=False)
    config_path=ROOT/'app/config/device-e2e.local.json'
    metadata={'run_id':args.run_id,'started_utc':datetime.now(timezone.utc).isoformat(),'commit':subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip(),'dirty':bool(subprocess.check_output(['git','status','--porcelain'],cwd=ROOT,text=True).strip()),'environment':'Android real / Supabase LOCAL / datos ficticios','callbacks':[]}
    sources=sorted([*ROOT.glob('app/lib/**/*.dart'),*ROOT.glob('app/integration_test/**/*.dart'),ROOT/'app/pubspec.yaml',ROOT/'app/pubspec.lock'])
    digest=hashlib.sha256()
    for path in sources:
        digest.update(path.relative_to(ROOT).as_posix().encode());digest.update(path.read_bytes().replace(b'\r\n',b'\n'))
    metadata['source_sha256']=digest.hexdigest()
    def adb(*command,**options):
        return subprocess.run([args.adb,'-s',args.device,*command],capture_output=True,**options)
    old_reverse=adb('reverse','--list',text=True).stdout
    assert not any('tcp:54321' in line and not line.strip().endswith('tcp:54321 tcp:54321') for line in old_reverse.splitlines()),'Port 54321 already has a conflicting device mapping'
    opened_mapping='tcp:54321 tcp:54321' not in old_reverse
    tunnel=subprocess.run([args.adb,'-s',args.device,'reverse','tcp:54321','tcp:54321'],capture_output=True)
    if tunnel.returncode!=0:
        metadata.update({'status':'BLOCKED_DEVICE','reason':'ADB no pudo establecer el túnel USB; prueba no iniciada','finished_utc':datetime.now(timezone.utc).isoformat()})
        (output/'metadata.json').write_text(json.dumps(metadata,ensure_ascii=False,indent=2),encoding='utf-8')
        print(json.dumps({'status':'BLOCKED_DEVICE','evidence':str(output)}))
        raise SystemExit(2)
    primary_email=f'nido-device-{uuid.uuid4().hex}@example.test'
    primary_password=secrets.token_urlsafe(20)+'Aa1!'
    new_password=secrets.token_urlsafe(20)+'Bb2!'
    stop=threading.Event();watch_errors=[];seen=set();passed=[];exit_code=1
    try:
        with LocalSupabase() as db:
            friend=db.actor('Persona Móvil Dos')
            config={'SUPABASE_URL':db.url,'SUPABASE_PUBLISHABLE_KEY':db.key,'SUPABASE_LOCAL_TEST':True,'E2E_EMAIL':primary_email,'E2E_PASSWORD':primary_password,'E2E_NEW_PASSWORD':new_password,'E2E_FRIEND_EMAIL':friend['email'],'E2E_FRIEND_PASSWORD':friend['password'],'E2E_FRIEND_PUBLIC_ID':friend['public_id'],'E2E_FAMILY_NAME':'Familia móvil '+uuid.uuid4().hex[:6]}
            config_path.write_text(json.dumps(config),encoding='utf-8')
            secrets_to_mask=[primary_password,new_password,friend['password']]
            def mail_watcher():
                opener=urllib.request.build_opener(NoRedirect())
                try:
                    while not stop.wait(.4):
                        with urllib.request.urlopen(db.mail_url+'/api/v1/messages',timeout=10) as response:
                            messages=json.load(response).get('messages',[])
                        for message in messages:
                            if message['ID'] in seen or not any(t.get('Address','').lower()==primary_email for t in message.get('To',[])):
                                continue
                            seen.add(message['ID'])
                            with urllib.request.urlopen(db.mail_url+'/api/v1/message/'+message['ID'],timeout=10) as response:
                                body=json.load(response)
                            links=[html.unescape(value) for value in re.findall(r'href=[\"\x27]([^\"\x27]+)',body.get('HTML',''))]
                            link=next((value for value in links if urllib.parse.urlparse(value).path=='/auth/v1/verify'),None)
                            if not link:
                                continue
                            parsed=urllib.parse.urlparse(link)
                            assert parsed.hostname in ('127.0.0.1','localhost') and parsed.port==54321,'Local auth link expected'
                            query=urllib.parse.parse_qs(parsed.query)
                            try:
                                opener.open(link,timeout=15)
                                raise AssertionError('Auth verification did not redirect')
                            except urllib.error.HTTPError as error:
                                assert error.code in (302,303),'Auth email verification failed'
                                callback=error.headers.get('Location','')
                            uri=urllib.parse.urlparse(callback)
                            assert uri.scheme=='nido' and uri.netloc=='auth' and uri.path=='/callback' and urllib.parse.parse_qs(uri.query).get('code'),'Scoped PKCE callback expected'
                            result=adb('shell','am','start','-a','android.intent.action.VIEW','-d',shlex.quote(callback),'-p','com.sqa.app',text=True)
                            assert result.returncode==0,'Android did not accept scoped callback'
                            metadata['callbacks'].append({'type':query.get('type',['unknown'])[0],'opened':True})
                except Exception as error:
                    watch_errors.append(type(error).__name__+': local email callback failed')
            watcher=threading.Thread(target=mail_watcher,daemon=True);watcher.start()
            try:
                command=[args.flutter,'test','integration_test/gerardo_mobile_test.dart','-d',args.device,'--dart-define-from-file=config/device-e2e.local.json','--reporter','expanded']
                with (output/'flutter-device.log').open('w',encoding='utf-8') as log:
                    process=subprocess.Popen(command,cwd=ROOT/'app',stdout=subprocess.PIPE,stderr=subprocess.STDOUT,text=True,encoding='utf-8',errors='replace')
                    for line in process.stdout:
                        safe=line
                        for value in secrets_to_mask:
                            safe=safe.replace(value,'[REDACTED_FIXTURE]')
                        log.write(safe);log.flush()
                        if 'CAPTURE_READY: ' in safe:
                            name=safe.split('CAPTURE_READY: ',1)[1].strip()
                            assert name in ('01-mascota-android','02-arbol-android','03-cuenta-android'),'Unknown capture'
                            result=adb('exec-out','run-as','com.sqa.app','cat','cache/nido-e2e/'+name+'.png')
                            assert result.returncode==0 and result.stdout.startswith(b'\x89PNG'),'Android PNG not captured'
                            (output/(name+'.png')).write_bytes(result.stdout)
                            metadata.setdefault('screenshots',[]).append({'name':name+'.png','sha256':hashlib.sha256(result.stdout).hexdigest()})
                            ack=adb('shell','run-as','com.sqa.app','touch','cache/nido-e2e/'+name+'.copied')
                            assert ack.returncode==0,'Capture acknowledgement failed'
                        if 'PASS_CASE: ' in safe:
                            label=safe.split('PASS_CASE: ',1)[1].strip();passed.append(label);print(label,flush=True)
                    exit_code=process.wait()
            finally:
                stop.set();watcher.join(timeout=15)
                # Discover this exact newly registered synthetic account even
                # when Flutter failed before returning any test data.
                status,listing=db.request('/auth/v1/admin/users?page=1&per_page=100',admin=True)
                if status==200:
                    for user in listing.get('users',[]):
                        if user.get('email')==primary_email and user['id'] not in db.users:
                            db.users.append(user['id'])
                for name in ('01-mascota-android','02-arbol-android','03-cuenta-android'):
                    result=adb('exec-out','run-as','com.sqa.app','cat','cache/nido-e2e/'+name+'.png')
                    if result.returncode==0 and result.stdout.startswith(b'\x89PNG'):
                        (output/(name+'.png')).write_bytes(result.stdout)
                if watch_errors:
                    metadata['callback_error']=watch_errors[0]
    finally:
        if config_path.exists():
            config_path.unlink()
        if opened_mapping:
            adb('reverse','--remove','tcp:54321')
        metadata.update({'finished_utc':datetime.now(timezone.utc).isoformat(),'flutter_exit':exit_code,'cases':passed,'status':'PASS' if exit_code==0 and not watch_errors else 'FAIL'})
        (output/'metadata.json').write_text(json.dumps(metadata,ensure_ascii=False,indent=2),encoding='utf-8')
    print(json.dumps({'status':metadata['status'],'scenario_count':1,'completed_checkpoints':len(passed),'evidence':str(output)},ensure_ascii=False))
    raise SystemExit(0 if metadata['status']=='PASS' else 1)


if __name__=='__main__':
    main()
