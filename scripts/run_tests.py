#!/usr/bin/env python3
import subprocess,pathlib
root=pathlib.Path(__file__).resolve().parents[1]
(root/'build').mkdir(exist_ok=True)
subprocess.run(['iverilog','-g2012','-DFIXED','-s','regression','-o','build/regression.vvp','-f','sim/rtl.f','tb/regression.sv'],cwd=root,check=True,timeout=30)
for case in ['reset','fsm','held','digit1','ticket','display','recovery']:
 p=subprocess.run(['vvp','build/regression.vvp',f'+CASE={case}'],cwd=root,text=True,capture_output=True,timeout=30)
 (root/'build'/f'fixed-{case}.log').write_text(p.stdout+p.stderr)
 print(p.stdout.strip())
 p.check_returncode()

subprocess.run(['iverilog','-g2012','-s','short_press','-o','build/short-fixed.vvp','-f','sim/rtl.f','tb/short_press.sv'],cwd=root,check=True,timeout=30)
p=subprocess.run(['vvp','build/short-fixed.vvp'],cwd=root,text=True,capture_output=True,timeout=60)
(root/'build'/'fixed-short.log').write_text(p.stdout+p.stderr)
print(p.stdout.strip());p.check_returncode()
subprocess.run(['python3','scripts/scenarios.py'],cwd=root,check=True,timeout=30)
subprocess.run(['iverilog','-g2012','-s','board_regression','-o','build/board.vvp','-f','sim/rtl.f','tb/board_regression.sv'],cwd=root,check=True,timeout=30)
p=subprocess.run(['vvp','build/board.vvp'],cwd=root,text=True,capture_output=True,timeout=60)
(root/'build'/'board-tests.log').write_text(p.stdout+p.stderr);print(p.stdout.strip());p.check_returncode()
for mode in ('demo','hardware'):subprocess.run(['python3','scripts/build_model.py',mode],cwd=root,check=True,timeout=180)
p=subprocess.run(['python3','scripts/test_model.py'],cwd=root,text=True,capture_output=True,timeout=120)
(root/'build'/'model-tests.log').write_text(p.stdout+p.stderr);print(p.stdout.strip());p.check_returncode()
subprocess.run(['iverilog','-g2012','-s','hex4_probe','-o','build/hex4-fixed.vvp','-f','sim/rtl.f','tb/hex4_probe.sv'],cwd=root,check=True,timeout=30)
subprocess.run(['vvp','build/hex4-fixed.vvp'],cwd=root,check=True,timeout=30)
