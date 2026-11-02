`timescale 1ns/1ps
module regression;
 reg clk=0; always #10 clk=~clk;
 reg [3:0] KEY=4'b1111;
 reg [12:0] SW=0;
 wire [0:6] HEX0,HEX1,HEX2,HEX3,HEX6,HEX7;
 wire [7:0] LEDG; wire [17:0] LEDR;
 TINYPROJECT dut(.KEY(KEY),.CLOCK_50(clk),.SW(SW),.HEX0(HEX0),.HEX1(HEX1),.HEX2(HEX2),.HEX3(HEX3),.HEX6(HEX6),.HEX7(HEX7),.LEDG(LEDG),.LEDR(LEDR));
 reg [8*32-1:0] scenario; integer pulses=0;
 always @(posedge LEDG[4]) if(KEY[0]) pulses=pulses+1;
 task cycles(input integer n); repeat(n) @(negedge clk); endtask
 task check(input bit ok,input string msg); if(!ok) $fatal(1,"%s: %s sum=%0d state=%0d ticket=%b",scenario,msg,dut.sum,dut.D1.State,LEDG[4]); endtask
 task reset; KEY=4'b1110; SW=0; cycles(4); KEY=4'b1111; cycles(4); pulses=0; endtask
 task press(input integer sw); SW=13'(sw); cycles(5); KEY[3]=0; cycles(6); KEY[3]=1; cycles(50); endtask
 initial begin #1000000; $fatal(1,"timeout"); end
 initial begin
  `ifdef FIXED
  force dut.ce=1'b1;
`else
  force dut.Clk=clk;
`endif // functional tests bypass only the original divider; hardware timing tested separately
  if(!$value$plusargs("CASE=%s",scenario)) scenario="reset";
  $dumpfile($sformatf("build/%0s.vcd",scenario)); $dumpvars(0,regression);
  reset;
  case(scenario)
   "reset": begin check(LEDG[4]===1'b0,"Ticket must reset to zero"); check(dut.sum===0,"balance reset"); end
   "fsm": begin force dut.D1.State=3'd7;force dut.D1.IN=1'b1;#1;check(dut.D1.NextState===3'd1,"S7 must accept next press (unit state injection)");release dut.D1.State;release dut.D1.IN;end
   "ticket": begin press(4);press(64);check(LEDG[4]===1'b1,"issuance LED must remain on until next selection");end
   "held": begin SW=1;cycles(5);KEY[3]=0;cycles(180);KEY[3]=1;cycles(50);check(dut.sum===500,"one held press must create one deposit");end
   "display": begin
    press(4);SW=1;cycles(5);KEY[3]=0;
    repeat(50)begin cycles(1);check({HEX3,HEX2,HEX1,HEX0}==={7'b0100100,7'b0000001,7'b0000001,7'b0000001} || {HEX3,HEX2,HEX1,HEX0}==={7'b0100100,7'b0100100,7'b0000001,7'b0000001},"display must hold a completed decimal balance during conversion");end
   end
   "digit1": begin press(4);press(64);check(HEX3===7'b1001111,"digit one must light segments 1 and 2");end
   default: $fatal(1,"unknown scenario");
  endcase
  $display("PASS %s",scenario); $finish;
 end
endmodule
