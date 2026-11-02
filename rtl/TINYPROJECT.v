`default_nettype none
// 원본 datapath와 double-dabble FSM을 유지한다. DIV_BITS=20은 원래 분주 주기이다.
module TINYPROJECT #(
 parameter integer DIV_BITS = 20
)(
 input wire [3:0] KEY,
 input wire CLOCK_50,
 input wire [12:0] SW,
 /* verilator lint_off ASCRANGE */
 output wire [0:6] HEX0, HEX1, HEX2, HEX3, HEX4, HEX6, HEX7,
 /* verilator lint_on ASCRANGE */
 output wire [7:0] LEDG,
 output wire [17:0] LEDR
);
 wire rst_ = ~KEY[0];
 reg [DIV_BITS-1:0] Clk_Down;
 wire ce = (Clk_Down == {1'b0,{(DIV_BITS-1){1'b1}}});
 always @(posedge CLOCK_50 or posedge rst_)
  if(rst_) Clk_Down <= 0;
  else Clk_Down <= Clk_Down + 1'b1;

 // 보드의 Schmitt debounce 이후 비동기 신호를 동기화한다.
 reg in_meta, in_sync, previousIN;
 reg [12:0] sw_meta, sw_sync;
 reg pending;
 reg [12:0] pending_sw;
 wire load,shift,loadbin,done,hap,happ,prt;
 reg Ticket;
 wire ready = loadbin && (!done || !Ticket);
 always @(posedge CLOCK_50 or posedge rst_) begin
  if(rst_) begin
   in_meta<=0;in_sync<=0;previousIN<=0;
   sw_meta<=0;sw_sync<=0;pending<=0;pending_sw<=0;
  end else begin
   in_meta<=~KEY[3];in_sync<=in_meta;previousIN<=in_sync;
   sw_meta<=SW;sw_sync<=sw_meta;
   if(ce && ready && pending) pending<=0;
   if(in_sync && !previousIN && ready && !pending) begin
    pending<=1;pending_sw<=sw_sync;
   end
  end
 end
 LAB4c D1(.rst_(rst_),.IN(pending),.clock(CLOCK_50),.enable(ce),
  .Ticket(Ticket),.shift(shift),.load(load),.loadbin(loadbin),
  .done(done),.hap(hap),.happ(happ),.prt(prt));
 reg [12:0] switch,bin,sum1;
 reg [13:0] sum;
 reg issue /* verilator public_flat_rd */; // 진단용 실제 RTL 발권 이벤트: CLOCK_50 한 주기
 reg [3:0] bcd0,bcd1,bcd2,bcd3,bcd6,bcd7;
 reg [3:0] display0,display1,display2,display3;
 wire [12:0] selection = pending ? pending_sw : sw_sync;
 assign LEDG={3'b000,Ticket,4'b0000};
 assign LEDR=18'b0;
 assign HEX4=7'b0000001;
 always @(posedge CLOCK_50 or posedge rst_) begin
  if(rst_) begin
   switch<=0;bin<=0;sum<=0;sum1<=0;Ticket<=0;issue<=0;bcd6<=0;bcd7<=0;
  end else begin
   switch<=sw_sync;
   issue<=0;
   if(switch!=sw_sync) Ticket<=0;
   if(ce) begin
    if(loadbin) begin
     case(selection)
      13'd1:bin<=13'd500;
      13'd2:bin<=13'd1000;
      13'd4:bin<=13'd5000;
      13'd64:bin<=13'd3300;
      13'd128:bin<=13'd6600;
      default:bin<=0;
     endcase
    end else if(hap) begin
     if(bin==500 || bin==1000 || bin==5000) begin
      if(sum+{1'b0,bin} >= 14'd8000) sum<=14'd8000;
      else sum<=sum+{1'b0,bin};
     end else if(bin==3300 && sum>={1'b0,bin}) begin
      sum<=sum-{1'b0,bin};Ticket<=1;issue<=1;bcd6<=bcd6+1'b1;
     end else if(bin==6600 && sum>={1'b0,bin}) begin
      sum<=sum-{1'b0,bin};Ticket<=1;issue<=1;bcd7<=bcd7+1'b1;
     end
    end else if(happ) sum1<=sum[12:0];
    else if(shift) sum1<={sum1[11:0],1'b0};
   end
  end
 end
 // 표시 작업 레지스터와 보드 표시를 분리: 변환 중 이전 완성 값을 유지한다.
 always @(posedge CLOCK_50 or posedge rst_) begin
  if(rst_) begin
   bcd0<=0;bcd1<=0;bcd2<=0;bcd3<=0;
   display0<=0;display1<=0;display2<=0;display3<=0;
  end else if(ce) begin
   if(hap) begin bcd0<=0;bcd1<=0;bcd2<=0;bcd3<=0;end
   else if(load) begin
    if(bcd0>4) bcd0<=bcd0+4'd3;
    if(bcd1>4) bcd1<=bcd1+4'd3;
    if(bcd2>4) bcd2<=bcd2+4'd3;
    if(bcd3>4) bcd3<=bcd3+4'd3;
   end else if(shift) begin
    bcd0<={bcd0[2:0],sum1[12]};bcd1<={bcd1[2:0],bcd0[3]};
    bcd2<={bcd2[2:0],bcd1[3]};bcd3<={bcd3[2:0],bcd2[3]};
   end
   if(done || prt) begin
    display0<=bcd0;display1<=bcd1;display2<=bcd2;display3<=bcd3;
   end
  end
 end
 bin7seg u0(display0,HEX0);bin7seg u1(display1,HEX1);
 bin7seg u2(display2,HEX2);bin7seg u3(display3,HEX3);
 bin7seg u6(bcd6,HEX6);bin7seg u7(bcd7,HEX7);
 // KEY1/2는 과제에서 사용하지 않는다.
 wire unused_keys = &{1'b0,KEY[2:1]};
endmodule
`default_nettype wire
