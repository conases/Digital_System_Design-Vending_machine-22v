"""PDF 1~2쪽의 십진 금액만 사용하는 독립 기준. RTL BCD/분주 구현식을 사용하지 않음."""
from collections import deque
CASH={1:500,2:1000,4:5000}
PRICE={64:3300,128:6600}
ACTIONS=tuple(CASH)+tuple(PRICE)
def balance_after(balance,sw):
 if sw in CASH:return min(8000,balance+CASH[sw])
 if sw in PRICE and balance>=PRICE[sw]:return balance-PRICE[sw]
 return balance

def paths():
 result={0:[]};queue=deque([0])
 while queue:
  value=queue.popleft()
  for sw in ACTIONS:
   nxt=balance_after(value,sw)
   if nxt not in result:result[nxt]=result[value]+[sw];queue.append(nxt)
 return result

def scenarios():
 for balance,path in sorted(paths().items()):
  for sw in ACTIONS+(0,3,192,8191):
   yield f'balance-{balance}-input-{sw}',path+[sw]

SEGMENTS=[0b0000001,0b1001111,0b0010010,0b0000110,0b1001100,0b0100100,0b0100000,0b0001111,0,0b0000100]

def expected_hex(balance,c6,c7):
 return [SEGMENTS[(balance//(10**i))%10] for i in range(5)]+[None,SEGMENTS[c6],SEGMENTS[c7]]

def next_expected(balance,c6,c7,sw):
 issue=sw in PRICE and balance>=PRICE[sw]
 return balance_after(balance,sw),c6+int(issue and sw==64),c7+int(issue and sw==128),int(issue)

if __name__=='__main__':
 from pathlib import Path
 lines=[]
 for idx,(name,seq) in enumerate(scenarios()):
  lines.append(f'{idx} -1 0 0 0 0')
  b=c6=c7=0
  for sw in seq:
   b,c6,c7,issue=next_expected(b,c6,c7,sw)
   assert c6<10 and c7<10
   lines.append(f'{idx} {sw} {b} {c6} {c7} {issue}')
 Path('build/oracle.txt').write_text('\n'.join(lines)+'\n')
 print(f'독립 기준: {len(paths())}개 잔액, {idx+1}개 시나리오, {len(lines)}개 단계')
