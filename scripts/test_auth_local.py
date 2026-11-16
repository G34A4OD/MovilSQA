"""HU-01 / TC-AUTH-01..04, TC-SEC-03. Real HTTP, LOCAL disposable Auth only.

CLI credentials stay in memory and never enter reports. Admin API is used only
to generate confirmation/recovery test tokens and clean up synthetic accounts.
All access assertions use user JWTs or the publishable key, never service_role.
"""
import base64
import json
import os
from pathlib import Path
import secrets
import subprocess
import time
import urllib.error
import urllib.parse
import urllib.request
import uuid

ROOT = Path(__file__).resolve().parents[1]


def main():
    npx = 'npx.cmd' if os.name == 'nt' else 'npx'
    result = subprocess.run([npx, '--yes', 'supabase@3.1.0', 'status', '-o', 'json'], cwd=ROOT, capture_output=True, text=True, check=True)
    config = json.loads(result.stdout)
    base = config['API_URL']
    assert urllib.parse.urlparse(base).hostname in ('127.0.0.1', 'localhost'), 'Local-only test'
    public_key = config['PUBLISHABLE_KEY']
    service_key = config.get('SECRET_KEY') or config['SERVICE_ROLE_KEY']
    passed = []
    account_id = None
    email = f'nido-{uuid.uuid4().hex}@example.test'
    password = secrets.token_urlsafe(24) + 'Aa1!'

    def request(path, body=None, *, token=None, admin=False, method=None):
        headers = {'apikey': service_key if admin else public_key, 'Content-Type': 'application/json'}
        if token:
            headers['Authorization'] = 'Bearer ' + token
        # Modern secret keys are passed via apikey, not as a JWT.
        if admin and service_key.startswith('eyJ'):
            headers['Authorization'] = 'Bearer ' + service_key
        req = urllib.request.Request(base + path, data=None if body is None else json.dumps(body).encode(), headers=headers, method=method or ('POST' if body is not None else 'GET'))
        try:
            with urllib.request.urlopen(req, timeout=20) as response:
                raw = response.read()
                return response.status, json.loads(raw) if raw else None
        except urllib.error.HTTPError as error:
            raw = error.read()
            return error.code, json.loads(raw) if raw else None

    def check(condition, label):
        if not condition:
            raise AssertionError(label)  # Never include request/response tokens.
        passed.append(label)

    try:
        status, signup = request('/auth/v1/signup', {'email': email, 'password': password})
        check(status == 200 and not signup.get('access_token'), 'TC-AUTH-01: registro sin sesión antes de verificar')
        account_id = signup.get('id') or signup['user']['id']
        status, _ = request('/auth/v1/token?grant_type=password', {'email': email, 'password': password})
        check(status == 400, 'TC-AUTH-01: login sin correo confirmado denegado')
        status, link = request('/auth/v1/admin/generate_link', {'type': 'signup', 'email': email, 'password': password}, admin=True)
        check(status == 200 and 'hashed_token' in link, 'TC-AUTH-01: token ficticio de confirmación preparado')
        status, _ = request('/auth/v1/verify', {'type': 'signup', 'token_hash': link['hashed_token']})
        check(status == 200, 'TC-AUTH-01: verificación por Auth')
        status, _ = request('/auth/v1/token?grant_type=password', {'email': email, 'password': 'Incorrecta123!'})
        check(status == 400, 'TC-AUTH-02: contraseña incorrecta denegada')
        status, s1 = request('/auth/v1/token?grant_type=password', {'email': email, 'password': password})
        check(status == 200 and bool(s1.get('access_token')), 'TC-AUTH-02: acceso confirmado permitido')
        status, s2 = request('/auth/v1/token?grant_type=password', {'email': email, 'password': password})
        check(status == 200 and s2['access_token'] != s1['access_token'], 'TC-SEC-03: segunda sesión independiente')
        sql = f"insert into public.profiles(user_id,full_name) values ('{uuid.UUID(account_id)}','Persona HTTP ficticia');"
        docker = os.environ.get('DOCKER_BIN', 'docker')
        subprocess.run([docker, 'exec', '-i', 'supabase_db_nido', 'psql', '-U', 'postgres', '-d', 'postgres', '-v', 'ON_ERROR_STOP=1'], input=sql, text=True, capture_output=True, check=True)
        status, rows = request('/rest/v1/profiles?select=public_id', token=s1['access_token'])
        check(status == 200 and len(rows) == 1, 'TC-SEC-03: JWT de usuario lee fila autorizada')
        status, _ = request('/rest/v1/profiles?select=public_id')
        check(status in (401, 403), 'TC-SEC-01: clave pública sola no lee perfiles')
        status, _ = request('/auth/v1/logout?scope=local', token=s1['access_token'], method='POST')
        check(status == 204, 'TC-AUTH-04: cierre real de sesión S1')
        payload = s1['access_token'].split('.')[1]
        claims = json.loads(base64.urlsafe_b64decode(payload + '=' * (-len(payload) % 4)))
        check(claims['exp'] > time.time(), 'TC-SEC-03: token capturado todavía no expiró')
        status, rows = request('/rest/v1/profiles?select=public_id', token=s1['access_token'])
        check(status == 200 and rows == [], 'TC-SEC-03: token S1 después de logout no lee filas')
        status, rows = request('/rest/v1/profiles?select=public_id', token=s2['access_token'])
        check(status == 200 and len(rows) == 1, 'TC-SEC-03: S2 viva no reactiva S1')
        status, _ = request('/auth/v1/token?grant_type=refresh_token', {'refresh_token': s1['refresh_token']})
        check(status == 400, 'TC-AUTH-04: refresh revocado denegado')
        status, _ = request('/auth/v1/recover', {'email': email})
        check(status == 200, 'TC-AUTH-03: solicitud real de recuperación')
        status, link = request('/auth/v1/admin/generate_link', {'type': 'recovery', 'email': email}, admin=True)
        check(status == 200, 'TC-AUTH-03: token ficticio de recuperación preparado')
        status, recovered = request('/auth/v1/verify', {'type': 'recovery', 'token_hash': link['hashed_token']})
        check(status == 200 and bool(recovered.get('access_token')), 'TC-AUTH-03: enlace de recuperación aceptado por Auth')
        new_password = secrets.token_urlsafe(24) + 'Aa2!'
        status, _ = request('/auth/v1/user', {'password': new_password}, token=recovered['access_token'], method='PUT')
        check(status == 200, 'TC-AUTH-03: contraseña actualizada por Auth')
        status, _ = request('/auth/v1/verify', {'type': 'recovery', 'token_hash': link['hashed_token']})
        check(status in (400, 401, 403), 'TC-AUTH-03: enlace de un solo uso')
        status, _ = request('/auth/v1/token?grant_type=password', {'email': email, 'password': new_password})
        check(status == 200, 'TC-AUTH-03: acceso con contraseña nueva')
        print(json.dumps({'status': 'PASS', 'tests': len(passed), 'cases': passed}, ensure_ascii=False, indent=2))
    finally:
        if account_id:
            status, _ = request('/auth/v1/admin/users/' + account_id, admin=True, method='DELETE')
            if status != 200:
                raise AssertionError('No se pudo limpiar cuenta ficticia local')


if __name__ == '__main__':
    main()
