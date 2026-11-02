#!/usr/bin/env python3
"""원본은 변경하지 않고 동일한 실패 시나리오를 실행한다."""
import pathlib, subprocess, sys
root=pathlib.Path(__file__).resolve().parents[1]
build=root/'build'; build.mkdir(exist_ok=True)
cmd=['iverilog','-g2012','-Wall','-s','regression','-o','build/baseline.vvp','legacy/source/TINYPROJECT.v','tb/regression.sv']
p=subprocess.run(cmd,cwd=root,text=True,capture_output=True,timeout=30)
(build/'baseline-compile.log').write_text(p.stdout+p.stderr)
if p.returncode: sys.exit(p.returncode)
failed=[]
for case in ['reset','fsm','held','digit1','ticket']:
 p=subprocess.run(['vvp','build/baseline.vvp',f'+CASE={case}'],cwd=root,text=True,capture_output=True,timeout=30)
 (build/f'baseline-{case}.log').write_text(p.stdout+p.stderr)
 v=build/f'{case}.vcd'
 if v.exists():v.rename(build/f'baseline-{case}.vcd')
 print(f'{case}: '+('기대된 원본 실패' if p.returncode else '예상 밖 통과'))
 if not p.returncode: failed.append(case)
print('원본 기능 검증 성공을 의미하지 않음: 알려진 실패를 재현하는 명령')
sys.exit(bool(failed))
