#!/usr/bin/env python3
import subprocess,pathlib
root=pathlib.Path(__file__).resolve().parents[1]
(root/'build').mkdir(exist_ok=True)
subprocess.run(['iverilog','-g2012','-s','regression','-o','build/regression.vvp','-f','sim/rtl.f','tb/regression.sv'],cwd=root,check=True,timeout=30)
for case in ['reset','fsm','held','digit1','ticket']:
 p=subprocess.run(['vvp','build/regression.vvp',f'+CASE={case}'],cwd=root,text=True,capture_output=True,timeout=30)
 (root/'build'/f'fixed-{case}.log').write_text(p.stdout+p.stderr)
 print(p.stdout.strip())
 p.check_returncode()
