#!/usr/bin/env python3
import json,pathlib,sys
root=pathlib.Path(__file__).resolve().parents[1];sys.path.insert(0,str(root/'sim'))
from server import Model
model=Model('demo',root/'build/representative.vcd');history=[]
try:
 for sw in (4,64,2,128):
  for command in [(8,15,sw),(6,7,sw),(220,15,sw)]:
   s=model.step(*command);history.append({'input':dict(zip(('cycles','key','sw'),command)),'output':s})
 assert model.snapshot['balance']==2700 and model.snapshot['count6']==1 and model.snapshot['count7']==0
 (root/'build/representative.json').write_text(json.dumps(history,indent=2)+'\n')
 print('PASS representative: 5000 → ticket6 → 1700 → +1000 → 2700 → ticket7 insufficient; build/representative.vcd')
finally:model.close()
