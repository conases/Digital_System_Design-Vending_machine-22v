// 실제 app.js의 입력 핸들러/렌더러를 최소 DOM에서 실행하고 실제 HTTP RTL 출력과 대조한다.
// 브라우저 레이아웃/스크린샷 검사는 아니다.
const fs=require('node:fs'),vm=require('node:vm'),assert=require('node:assert/strict');
const base=process.env.RTL_URL||'http://127.0.0.1:8765';
const nodes=new Map();
class Element{
 constructor(){this.children=[];this.dataset={};this.classes=new Set();this.classList={toggle:(c,on)=>on?this.classes.add(c):this.classes.delete(c),add:c=>this.classes.add(c),remove:c=>this.classes.delete(c)};}
 set innerHTML(value){this._html=value;for(const match of value.matchAll(/id="([^"]+)"/g)){const el=new Element();el.id=match[1];this.children.push(el);}if(value.includes('polygon'))this.polygons=Array.from({length:7},()=>new Element());if(value.includes('checkbox')){this.firstChild=new Element();this.firstChild.dataset.switch=value.match(/data-switch="(\d+)"/)[1];switches.push(this.firstChild);}}
 get innerHTML(){return this._html;}
 set id(value){this._id=value;nodes.set(value,this);}get id(){return this._id;}
 append(child){this.children.push(child);}setPointerCapture(){}
}
const switches=[];
for(const match of fs.readFileSync('ui/index.html','utf8').matchAll(/id="([^"]+)"/g)){const el=new Element();el.id=match[1];}
nodes.get('batch').value='240';nodes.get('refresh').value='100';
const requests=[];
const context=vm.createContext({document:{getElementById:id=>nodes.get(id),createElement:()=>new Element(),querySelectorAll:selector=>selector==='[data-switch]'?switches:(nodes.get(selector.match(/^#(\w+) polygon$/)?.[1])?.polygons||[])},fetch:async(url,options)=>{const r=await fetch(base+url,options);if(options?.method==='POST')requests.push(JSON.parse(options.body));return r;},setInterval:()=>{},setTimeout,URL,Blob,console});
vm.runInContext(fs.readFileSync('ui/app.js','utf8'),context);
async function expression(s){return await vm.runInContext(s,context);}
async function settled(){await expression('queue');}
(async()=>{
 await nodes.get('reset').onclick();await settled();
 const activate=async i=>{for(const el of switches){const should=Number(el.dataset.switch)===i;if(!!el.checked!==should){el.checked=should;el.onchange({target:el});}}await settled();};
 const press=async()=>{nodes.get('key3').onpointerdown({preventDefault(){},pointerId:1});await settled();nodes.get('key3').onpointerup();await settled();nodes.get('advance').onclick();await settled();};
 await activate(2);await press();assert.equal(nodes.get('balance').textContent,'5,000 원');
 await activate(6);await press();assert.equal(nodes.get('balance').textContent,'1,700 원');
 assert(nodes.get('green4').classes.has('on'));
 const raw=[1,1,15,79,1,null,79,1];
 for(let digit=0;digit<8;digit++)for(let segment=0;segment<7;segment++)assert.equal(nodes.get(`hex${digit}`).polygons[segment].classes.has('on'),raw[digit]!==null&&!(raw[digit]&(1<<(6-segment))),`HEX${digit} segment${segment}`);
 assert.match(nodes.get('events').textContent,/issue = 1700/);
 const last=await expression('snapshot');
 assert(last.rtl.source_sha256);assert.equal(last.balance,1700);
 // 완료된 입력을 reset부터 재생해 같은 RTL 출력과 이벤트를 확인한다.
 const replay=requests.slice();
 for(const cmd of replay){const r=await fetch(base+'/api/step',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify(cmd)});assert(r.ok);}
 const after=await (await fetch(base+'/api/state')).json();assert.equal(after.balance,last.balance);assert.deepEqual(after.hex,last.hex);assert.equal(after.count6,1);
 // 실제 렌더러가 연결 오류를 표시하고 실행을 멈추는지 확인한다.
 context.fetch=async()=>{throw Error('test simulator disconnected');};
 await expression('send(1).catch(()=>{})');await settled();
 assert.match(nodes.get('connection').textContent,/RTL 연결 오류/);assert.equal(await expression('running'),false);
 console.log('PASS UI handlers → HTTP → Verilator: 5000 → ticket6 → 1700; 56 segment bits, issue event, replay, disconnect indicator');
 fs.writeFileSync('build/ui-integration.json',JSON.stringify({commands:replay,output:last,replayed:after},null,2)+'\n');
})().catch(e=>{console.error(e);process.exitCode=1;});
