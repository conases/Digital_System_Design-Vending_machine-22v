#!/usr/bin/env python3
import pathlib,subprocess
root=pathlib.Path(__file__).resolve().parents[1];(root/'build').mkdir(exist_ok=True)
subprocess.run(['iverilog','-g2012','-DORIGINAL','-s','short_press','-o','build/short-original.vvp','-f','sim/legacy.f','tb/short_press.sv'],cwd=root,check=True,timeout=30)
p=subprocess.run(['vvp','build/short-original.vvp'],cwd=root,text=True,capture_output=True,timeout=60)
(root/'build'/'baseline-hardware.log').write_text(p.stdout+p.stderr)
(root/'build'/'short.vcd').rename(root/'build'/'baseline-hardware.vcd')
assert p.returncode and 'short press lost: expected 500 got 0' in p.stdout,(p.returncode,p.stdout,p.stderr)
print('PASS 원본 기본 분주에서 5클록 누름 유실 재현 (기능 검증 성공 아님)')
