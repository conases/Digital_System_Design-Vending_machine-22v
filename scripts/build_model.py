#!/usr/bin/env python3
"""RTL 소스 해시가 같을 때만 기존 실행 모델을 재사용한다."""
import hashlib,json,pathlib,subprocess,sys
root=pathlib.Path(__file__).resolve().parents[1]
mode=sys.argv[1] if len(sys.argv)>1 else 'demo'
if mode not in ('demo','hardware'):raise SystemExit('mode: demo or hardware')
div=2 if mode=='demo' else 20
files=[root/x for x in (root/'sim/rtl.f').read_text().splitlines()]+[root/'sim/board_model.sv',root/'sim/main.cpp',pathlib.Path(__file__)]
version=subprocess.check_output(['verilator','--version'],text=True).strip()
fingerprint=hashlib.sha256(b''.join(p.read_bytes() for p in files)+version.encode()+mode.encode()).hexdigest()
out=root/'build'/f'model-{mode}';meta=out/'version.json';exe=out/'Vboard_model'
if exe.exists() and meta.exists() and json.loads(meta.read_text())['source_sha256']==fingerprint:
 print(f'{mode}: 기존 RTL 모델 사용');raise SystemExit(0)
out.mkdir(parents=True,exist_ok=True)
cmd=['verilator','--cc','--exe','--build','--trace','--timescale','1ns/1ns','--Wall','--top-module','board_model',f'-GDIV_BITS={div}','--Mdir',str(out),'-f','sim/rtl.f','sim/board_model.sv',str(root/'sim/main.cpp'),'-CFLAGS','-std=c++17']
p=subprocess.run(cmd,cwd=root,text=True,capture_output=True,timeout=180)
(out/'build.log').write_text(p.stdout+p.stderr)
if p.returncode:print(p.stdout+p.stderr);raise SystemExit(p.returncode)
meta.write_text(json.dumps({'mode':mode,'div_bits':div,'source_sha256':fingerprint,'verilator':version,'clock_hz':50000000},indent=2)+'\n')
print(f'{mode}: 모델 빌드 성공 DIV_BITS={div} SHA256={fingerprint[:12]}')
