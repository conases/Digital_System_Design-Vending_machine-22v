#!/usr/bin/env python3
"""로컬 UI ↔ 실행 중인 Verilator 모델. 외부 Python 패키지가 필요 없다."""
import argparse,http.server,json,pathlib,select,subprocess,threading,time,sys
ROOT=pathlib.Path(__file__).resolve().parents[1]
class Model:
 def __init__(self,mode='demo',trace=None):
  self.mode=mode;self.directory=ROOT/'build'/f'model-{mode}'
  self.version=json.loads((self.directory/'version.json').read_text())
  args=[str(self.directory/'Vboard_model')]
  if trace:args+=['--trace',str(trace)]
  self.process=subprocess.Popen(args,stdin=subprocess.PIPE,stdout=subprocess.PIPE,stderr=subprocess.PIPE,text=True,bufsize=1)
  self.lock=threading.Lock();self.history=[];self.snapshot=None
  self.step(5,14,0);self.step(5,15,0)
 def step(self,cycles,key,sw):
  if any(type(v) is not int for v in (cycles,key,sw)) or not(0<=cycles<=50000000 and 0<=key<=15 and 0<=sw<=8191):raise ValueError('cycles 0..50000000, KEY 0..15, SW 0..8191')
  with self.lock:
   if self.process.poll() is not None:raise RuntimeError('RTL 시뮬레이터 연결 종료')
   self.process.stdin.write(f'{cycles} {key} {sw}\n');self.process.stdin.flush()
   if not select.select([self.process.stdout],[],[],20)[0]:raise RuntimeError('RTL 응답 시간 초과')
   line=self.process.stdout.readline()
   if not line:raise RuntimeError('RTL 시뮬레이터 연결 종료')
   result=json.loads(line)
   if 'error' in result:raise RuntimeError(result['error'])
   result['rtl']=self.version
   self.snapshot=result
   record={'input':{'cycles':cycles,'key':key,'sw':sw},'output':result}
   self.history.append(record)
   with (ROOT/'build'/'session.jsonl').open('a')as f:f.write(json.dumps(record)+'\n')
   return result
 def close(self):
  if not self.process.stdin.closed:self.process.stdin.close()
  try:self.process.wait(timeout=3)
  except subprocess.TimeoutExpired:self.process.terminate();self.process.wait(timeout=3)

def serve(mode,port):
 model=Model(mode)
 class Handler(http.server.BaseHTTPRequestHandler):
  def json(self,data,status=200):
   raw=json.dumps(data).encode();self.send_response(status);self.send_header('Content-Type','application/json');self.send_header('Cache-Control','no-store');self.send_header('Content-Length',str(len(raw)));self.end_headers();self.wfile.write(raw)
  def do_GET(self):
   if self.path=='/api/state':
    if model.process.poll() is not None:return self.json({'error':'RTL 시뮬레이터 연결 종료'},503)
    return self.json(model.snapshot)
   if self.path=='/api/history':return self.json({'format':1,'rtl':model.version,'commands':[x['input'] for x in model.history]})
   paths={'/':'index.html','/app.js':'app.js','/style.css':'style.css'}
   if self.path not in paths:return self.send_error(404)
   file=ROOT/'ui'/paths[self.path];raw=file.read_bytes()
   self.send_response(200);self.send_header('Content-Type',{'html':'text/html; charset=utf-8','js':'text/javascript; charset=utf-8','css':'text/css; charset=utf-8'}[file.suffix[1:]]);self.send_header('Content-Length',str(len(raw)));self.end_headers();self.wfile.write(raw)
  def do_POST(self):
   if self.path!='/api/step':return self.send_error(404)
   try:
    size=int(self.headers.get('Content-Length','0'))
    if size>4096:raise ValueError('요청 크기 초과')
    data=json.loads(self.rfile.read(size));self.json(model.step(data['cycles'],data['key'],data['sw']))
   except (ValueError,KeyError,json.JSONDecodeError)as e:self.json({'error':str(e)},400)
   except (RuntimeError,BrokenPipeError)as e:self.json({'error':str(e)},503)
  def log_message(self,fmt,*args):pass
 server=http.server.ThreadingHTTPServer(('127.0.0.1',port),Handler)
 print(f'가상 DE2-115: http://127.0.0.1:{server.server_port} / {mode} DIV_BITS={model.version["div_bits"]}',flush=True)
 try:server.serve_forever()
 except KeyboardInterrupt:pass
 finally:server.server_close();model.close()
if __name__=='__main__':
 parser=argparse.ArgumentParser();parser.add_argument('--mode',choices=['demo','hardware'],default='demo');parser.add_argument('--port',type=int,default=8765);args=parser.parse_args();serve(args.mode,args.port)
