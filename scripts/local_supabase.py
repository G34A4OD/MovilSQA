"""Helpers for disposable, synthetic LOCAL integration fixtures. Never hosted."""
import json
import os
from pathlib import Path
import secrets
import subprocess
import urllib.error
import urllib.parse
import urllib.request
import uuid

ROOT = Path(__file__).resolve().parents[1]


class LocalSupabase:
    def __init__(self):
        npx = 'npx.cmd' if os.name == 'nt' else 'npx'
        result = subprocess.run([npx, '--yes', 'supabase@3.1.0', 'status', '-o', 'json'], cwd=ROOT, capture_output=True, text=True, check=True)
        config = json.loads(result.stdout)
        self.url = config['API_URL']
        assert urllib.parse.urlparse(self.url).hostname in ('127.0.0.1', 'localhost'), 'Local-only fixtures'
        self.key = config['PUBLISHABLE_KEY']
        self.admin_key = config.get('SECRET_KEY') or config['SERVICE_ROLE_KEY']
        self.users = []
        self.families = []

    def request(self, path, body=None, *, token=None, admin=False, method=None):
        headers = {'apikey': self.admin_key if admin else self.key, 'Content-Type':'application/json'}
        if token:
            headers['Authorization'] = 'Bearer ' + token
        if admin and self.admin_key.startswith('eyJ'):
            headers['Authorization'] = 'Bearer ' + self.admin_key
        req = urllib.request.Request(self.url+path, data=None if body is None else json.dumps(body).encode(), headers=headers, method=method or ('POST' if body is not None else 'GET'))
        try:
            with urllib.request.urlopen(req,timeout=15) as response:
                raw = response.read()
                return response.status,json.loads(raw) if raw else None
        except urllib.error.HTTPError as error:
            raw = error.read()
            return error.code,json.loads(raw) if raw else None

    def rpc(self, name, params, actor):
        return self.request('/rest/v1/rpc/'+name,params,token=actor['token'])

    def actor(self, label):
        email = f'nido-{uuid.uuid4().hex}@example.test'
        password = secrets.token_urlsafe(24)+'Aa1!'
        status,user = self.request('/auth/v1/admin/users',{'email':email,'password':password,'email_confirm':True},admin=True)
        assert status in (200,201),'Create synthetic Auth fixture'
        self.users.append(user['id'])
        status,session = self.request('/auth/v1/token?grant_type=password',{'email':email,'password':password})
        assert status==200,'Login synthetic fixture'
        actor = {'user_id':user['id'],'token':session['access_token']}
        status,profile = self.rpc('complete_profile',{'p_full_name':label,'p_blood_type':'O+','p_identity_card':'FICTICIO','p_birth_date':'2000-01-01','p_address':'Domicilio ficticio'},actor)
        assert status==200,'Create synthetic profile through user RPC'
        actor['public_id']=profile['public_id']
        return actor

    def family(self, actor, label):
        status,family = self.rpc('create_family',{'p_name':label,'p_request_id':str(uuid.uuid4())},actor)
        assert status==200,'Create synthetic family through user RPC'
        self.families.append(family['id'])
        return family

    def close(self):
        if self.families:
            ids=','.join("'"+str(uuid.UUID(value))+"'" for value in self.families)
            sql=f'delete from private.cleanup_jobs where family_id in ({ids}); delete from public.families where id in ({ids});'
            subprocess.run([os.environ.get('DOCKER_BIN','docker'),'exec','-i','supabase_db_nido','psql','-U','postgres','-d','postgres','-v','ON_ERROR_STOP=1'],input=sql,text=True,capture_output=True,check=True)
        for user_id in self.users:
            status,_=self.request('/auth/v1/admin/users/'+str(uuid.UUID(user_id)),admin=True,method='DELETE')
            assert status==200,'Clean synthetic Auth fixture'

    def sql(self, query):
        result=subprocess.run([os.environ.get('DOCKER_BIN','docker'),'exec','-i','supabase_db_nido','psql','-X','-q','-A','-t','-U','postgres','-d','postgres','-v','ON_ERROR_STOP=1'],input=query,text=True,capture_output=True,check=True)
        return result.stdout.strip()

    def __enter__(self):
        return self

    def __exit__(self, *args):
        self.close()
