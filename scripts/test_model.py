#!/usr/bin/env python3
import json,pathlib,sys,subprocess
ROOT=pathlib.Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'sim'))
from server import Model
from scenarios import scenarios,next_expected,expected_hex

def check(s,b,c6,c7,name):
 assert (s['balance'],s['count6'],s['count7'],s['hex'])==(b,c6,c7,expected_hex(b,c6,c7)),(name,s,b,c6,c7)

def run():
 model=Model('demo',ROOT/'build'/'model-demo.vcd');count=steps=0
 try:
  for name,sequence in scenarios():
   model.step(5,14,0);s=model.step(8,15,0);b=c6=c7=0;check(s,b,c6,c7,name)
   for sw in sequence:
    model.step(8,15,sw);a=model.step(6,7,sw);s=model.step(220,15,sw)
    b,c6,c7,issued=next_expected(b,c6,c7,sw);check(s,b,c6,c7,name)
    assert sum(e['kind']=='issue' for x in (a,s) for e in x['events'])==issued,(name,s)
    steps+=1
   count+=1
  # 수량 0..9, 같은 티켓 반복, 긴 누름.
  model.step(5,14,0);model.step(8,15,0)
  b=c6=c7=0
  for i in range(9):
   for sw in (4,64):
    model.step(8,15,sw);model.step(6,7,sw);s=model.step(220,15,sw)
    b,c6,c7,issue=next_expected(b,c6,c7,sw);check(s,b,c6,c7,'count-nine')
  model.step(5,14,0);model.step(8,15,1);model.step(600,7,1);s=model.step(220,15,1);check(s,500,0,0,'long press')
  print(f'PASS Verilator demo: {count} scenarios, {steps} transactions; ticket count 0..9; held press')
 finally:model.close()
 # 원래 분주값: enable phase와 간격을 RTL 출력으로 관찰. 짧은 펄스도 포함.
 hw=Model('hardware')
 try:
  hw.step(8,15,1);hw.step(5,7,1);hw.step(5,15,1)
  # reset 해제 후 CLOCK_50 524288번째에서 첫 enable tick 완료.
  current=hw.snapshot['cycle']-5
  hw.step(524287-current,15,1);assert hw.snapshot['state']==0
  s=hw.step(1,15,1);assert s['state']==1
  hw.step(1048575,15,1);assert hw.snapshot['balance']==0
  s=hw.step(1,15,1);assert s['balance']==500
  s=hw.step(33000000,15,1);check(s,500,0,0,'hardware display')
  print('PASS Verilator hardware: first tick 524288, period 1048576; short press and complete 00500 display')
 finally:hw.close()
if __name__=='__main__':run()
