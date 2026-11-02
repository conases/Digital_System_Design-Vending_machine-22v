#!/usr/bin/env python3
import os,pathlib,re,signal,subprocess
root=pathlib.Path(__file__).resolve().parents[1]
server=subprocess.Popen(['python3','sim/server.py','--port','0'],cwd=root,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,text=True)
try:
 line=server.stdout.readline();print(line.strip())
 match=re.search(r'http://127.0.0.1:\d+',line)
 if not match:raise RuntimeError('로컬 서버 시작 실패: '+line)
 env=os.environ.copy();env['RTL_URL']=match[0]
 for command in [['node','scripts/test_ui.js'],['python3','scripts/test_bridge.py']]:
  p=subprocess.run(command,cwd=root,env=env,text=True,capture_output=True,timeout=45)
  print(p.stdout.strip());(root/'build'/('ui-test.log' if command[0]=='node' else 'bridge-test.log')).write_text(p.stdout+p.stderr)
  p.check_returncode()
finally:
 server.send_signal(signal.SIGINT)
 try:server.wait(timeout=5)
 except subprocess.TimeoutExpired:server.terminate();server.wait(timeout=5)
