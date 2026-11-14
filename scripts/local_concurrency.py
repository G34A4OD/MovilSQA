"""Reusable two-connection SQL race fixture. No hosted DB, no secrets in logs."""
import base64
from concurrent.futures import ThreadPoolExecutor
import json
import os
import subprocess
import threading
import time


def race_transactions(db,actors,statements,isolation):
    assert isolation in ('READ COMMITTED','REPEATABLE READ')
    processes=[]
    try:
        for index,actor in enumerate(actors):
            process=subprocess.Popen([os.environ.get('DOCKER_BIN','docker'),'exec','-i','supabase_db_nido','psql','-X','-q','-A','-t','-U','postgres','-d','postgres','-v','ON_ERROR_STOP=1'],stdin=subprocess.PIPE,stdout=subprocess.PIPE,stderr=subprocess.PIPE,text=True,bufsize=1)
            processes.append(process)
            encoded=actor['token'].split('.')[1]
            claims=json.loads(base64.urlsafe_b64decode(encoded+'='*(-len(encoded)%4)))
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
            barrier.wait(timeout=10)
            _,error=processes[index].communicate(statements[index]+'; select pg_sleep(2); commit;\n',timeout=20)
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
        assert observed,'Transactions must demonstrate overlapping row-lock contention'
        return completed
    finally:
        for process in processes:
            if process.poll() is None:
                process.kill()
                process.wait(timeout=5)
