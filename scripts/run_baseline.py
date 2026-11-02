#!/usr/bin/env python3
"""원본은 변경하지 않고 동일한 실패 시나리오를 실행한다."""
import pathlib, subprocess, sys
root=pathlib.Path(__file__).resolve().parents[1]
build=root/'build'; build.mkdir(exist_ok=True)
cmd=['iverilog','-g2012','-Wall','-s','regression','-o','build/baseline.vvp','-f','sim/legacy.f','tb/regression.sv']
p=subprocess.run(cmd,cwd=root,text=True,capture_output=True,timeout=30)
(build/'baseline-compile.log').write_text(p.stdout+p.stderr)
if p.returncode: sys.exit(p.returncode)
failed=[]
expectations={
 'reset':'Ticket must reset to zero',
 'fsm':'S7 must accept next press',
 'held':'one held press must create one deposit',
 'digit1':'digit one must light segments 1 and 2',
 'ticket':'issuance LED must remain on until next selection',
 'display':'display must hold a completed decimal balance during conversion',
}
for case,expected in expectations.items():
 p=subprocess.run(['vvp','build/baseline.vvp',f'+CASE={case}'],cwd=root,text=True,capture_output=True,timeout=30)
 (build/f'baseline-{case}.log').write_text(p.stdout+p.stderr)
 v=build/f'{case}.vcd'
 if v.exists():v.rename(build/f'baseline-{case}.vcd')
 reproduced=p.returncode!=0 and 'FATAL:' in p.stdout and expected in p.stdout
 print(f'{case}: '+('기대된 원본 실패' if reproduced else '예상 실패 재현 안 됨'))
 if not reproduced: failed.append(case)
p=subprocess.run(['iverilog','-g2012','-s','hex4_probe','-o','build/hex4-legacy.vvp','-f','sim/legacy.f','tb/hex4_probe.sv'],cwd=root,text=True,capture_output=True,timeout=30)
(build/'baseline-hex4.log').write_text(p.stdout+p.stderr)
if not(p.returncode and 'HEX4' in p.stderr):failed.append('hex4')
else:print('hex4: 기대된 원본 포트 누락 재현')
print('원본 기능 검증 성공을 의미하지 않음: 알려진 실패를 재현하는 명령')
sys.exit(bool(failed))
