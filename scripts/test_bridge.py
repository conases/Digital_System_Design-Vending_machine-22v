#!/usr/bin/env python3
import json,pathlib,sys,re
ROOT=pathlib.Path(__file__).resolve().parents[1];sys.path.insert(0,str(ROOT/'sim'))
from server import Model
record=json.loads((ROOT/'build/ui-integration.json').read_text())
model=Model('demo',ROOT/'build/bridge.vcd');events=[]
try:
 for cmd in record['commands']:
  s=model.step(**cmd);events+=s['events']
 assert s['balance']==1700 and s['hex']==record['output']['hex'] and s['count6']==1
 model.close()
 expected=[e['cycle']*20 for e in events if e['kind']=='issue']
 # Verilator가 생성한 파형의 실제 issue 신호와 JSON 발권 이벤트 시간을 비교한다.
 assert '$timescale 1ns $end' in (ROOT/'build/bridge.vcd').read_text()
 symbols=[];timestamp=0;seen=[]
 for line in (ROOT/'build/bridge.vcd').read_text().splitlines():
  if '$var' in line and re.search(r'\sissue\s',line):symbols.append(line.split()[3])
  if line.startswith('#'):timestamp=int(line[1:])
  if symbols and line.strip()=='1'+symbols[0]:seen.append(timestamp)
 assert seen==expected,(seen,expected)
 print(f'PASS HTTP/UI sequence vs direct RTL and VCD: balance=1700, issue timestamps(ns)={seen}')
 terminated=Model('demo')
 try:
  terminated.process.terminate();terminated.process.wait(timeout=3)
  try:terminated.step(1,15,0)
  except RuntimeError:print('PASS actual model process termination raises connection error')
  else:raise AssertionError('dead RTL model returned fake state')
 finally:terminated.close()
finally:model.close()
