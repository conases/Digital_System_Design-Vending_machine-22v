'use strict';
const $=id=>document.getElementById(id);
let snapshot,key=15,sw=0,running=false,queue=Promise.resolve(),eventLines=[];
const polygons=['10,5 40,5 35,11 15,11','41,7 41,35 35,31 35,13','41,39 41,67 35,61 35,43','10,69 40,69 35,63 15,63','9,39 15,43 15,61 9,67','9,7 15,13 15,31 9,35','11,37 16,33 34,33 39,37 34,41 16,41'];
for(let i=7;i>=0;i--){const el=document.createElement('div');el.className='digit';el.innerHTML=`<svg viewBox="0 0 50 75" aria-label="HEX${i}">${polygons.map((p,j)=>`<polygon class="segment" data-segment="${j}" points="${p}"/>`).join('')}</svg><div class="label">HEX${i}${i===5?' · 미연결':''}</div>`;el.id=`hex${i}`;$('hexes').append(el);}
for(const [id,n,color]of[['green',8,''],['red',18,'red']])for(let i=n-1;i>=0;i--){const el=document.createElement('div');el.className='ledcell';el.innerHTML=`<div class="lamp ${color}" id="${id}${i}"></div>${i}`;$(id).append(el);}
for(let i=12;i>=0;i--){const el=document.createElement('label');el.className='sw';el.innerHTML=`<input type="checkbox" aria-label="SW${i}" data-switch="${i}">SW${i}`;el.firstChild.onchange=e=>{if(e.target.checked)sw|=1<<i;else sw&=~(1<<i);send(0,key,sw);};$('switches').append(el);}
for(let i=3;i>=0;i--){const b=document.createElement('button');b.className='key';b.id=`key${i}`;b.textContent=`KEY${i}${i===0?' Reset':i===3?' In':''}`;
 const change=pressed=>{key=pressed?key&~(1<<i):key|(1<<i);b.classList.toggle('pressed',pressed);send(5,key,sw);};
 b.onpointerdown=e=>{e.preventDefault();b.setPointerCapture(e.pointerId);change(true);};b.onpointerup=()=>change(false);b.onpointercancel=()=>change(false);b.onkeydown=e=>{if((e.code==='Space'||e.code==='Enter')&&!e.repeat){e.preventDefault();change(true);}};b.onkeyup=e=>{if(e.code==='Space'||e.code==='Enter'){e.preventDefault();change(false);}};$('keys').append(b);}
function log(line){eventLines.push(line);if(eventLines.length>2000)eventLines.shift();$('events').textContent=eventLines.join('\n');$('events').scrollTop=$('events').scrollHeight;}
function render(s){snapshot=s;key=s.key;sw=s.sw;$('connection').className='';$('connection').textContent='● RTL 연결됨';
 for(let i=0;i<8;i++)document.querySelectorAll(`#hex${i} polygon`).forEach((el,j)=>el.classList.toggle('on',s.hex[i]!==null&&!(s.hex[i]&(1<<(6-j)))));
 for(const[id,value,n]of[['green',s.ledg,8],['red',s.ledr,18]])for(let i=0;i<n;i++)$(`${id}${i}`).classList.toggle('on',!!(value&(1<<i)));
 document.querySelectorAll('[data-switch]').forEach(e=>e.checked=!!(sw&(1<<Number(e.dataset.switch))));
 for(let i=0;i<4;i++)$(`key${i}`).classList.toggle('pressed',!(key&(1<<i)));
 $('balance').textContent=s.balance.toLocaleString()+' 원';$('fsm').textContent=`S${s.state} / ${s.ready?'대기':'처리 중'}${s.pending?' · 입력 포착':''}`;
 $('cycle').textContent=s.cycle.toLocaleString();$('time').textContent=(s.time_ns/1e6).toFixed(6)+' ms';
 $('version').textContent=`RTL SHA256 ${s.rtl.source_sha256} · ${s.rtl.verilator}`;
 $('timing').textContent=s.rtl.mode==='demo'?'빠른 데모 · DIV_BITS=2 (하드웨어 기본값 20) · 시뮬레이션 클록 50 MHz · 화면 갱신은 별도 주기':'하드웨어 기본 타이밍 · DIV_BITS=20 · 50 MHz / 2²⁰ ≈ 47.68 FSM 단계/초';
 for(const e of s.events)log(`[${e.cycle}] ${e.kind} = ${e.value}`);
 if(s.events_truncated)log('이벤트 표시 용량 초과: 묶음 클록 수를 줄이세요.');
}
function disconnected(e){running=false;$('run').classList.remove('active');$('connection').textContent='RTL 연결 오류 · '+e.message;$('connection').className='error';log('연결 오류: '+e.message);}
function send(cycles,k=key,w=sw){const command={cycles:Number(cycles),key:k,sw:w};const job=queue.then(async()=>{const r=await fetch('/api/step',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify(command)});const s=await r.json();if(!r.ok||s.error)throw Error(s.error||'응답 오류');log(`입력 +${command.cycles} clocks KEY=${command.key} SW=${command.sw}`);render(s);return s;});queue=job.catch(disconnected);return job;}
async function tick(){if(!running)return;try{await send(Number($('batch').value));if(running)setTimeout(tick,Number($('refresh').value));}catch(e){disconnected(e);}}
$('run').onclick=()=>{if(!running){running=true;$('run').classList.add('active');tick();}};
$('pause').onclick=()=>{running=false;$('run').classList.remove('active');};
$('single').onclick=()=>send(1);$('advance').onclick=()=>send(Number($('batch').value));
$('reset').onclick=async()=>{running=false;$('run').classList.remove('active');await send(5,14,0);await send(5,15,0);};
$('clear').onclick=()=>{eventLines=[];$('events').textContent='';};
$('save').onclick=async()=>{try{await queue;const r=await fetch('/api/history');const record=await r.json();const u=URL.createObjectURL(new Blob([JSON.stringify(record,null,2)],{type:'application/json'}));const a=document.createElement('a');a.href=u;a.download='rtl-inputs.json';a.click();URL.revokeObjectURL(u);}catch(e){disconnected(e);}};
$('replay').onchange=async e=>{running=false;$('run').classList.remove('active');try{const record=JSON.parse(await e.target.files[0].text());if(!snapshot||record.rtl.source_sha256!==snapshot.rtl.source_sha256)throw Error('기록의 RTL 버전이 현재 모델과 다릅니다.');if(!Array.isArray(record.commands))throw Error('입력 기록 형식 오류');for(const cmd of record.commands)await send(cmd.cycles,cmd.key,cmd.sw);log('기록 재생 완료');}catch(err){log('재생 오류: '+err.message);}};
fetch('/api/state').then(async r=>{const s=await r.json();if(!r.ok||s.error)throw Error(s.error||'연결 실패');render(s);}).catch(disconnected);
setInterval(()=>{if(!running)fetch('/api/state').then(async r=>{const s=await r.json();if(!r.ok||s.error)throw Error(s.error||'연결 실패');}).catch(disconnected);},2000);
