`timescale 1ns/1ps
module regression;
 reg clk=0; always #10 clk=~clk;
 reg [3:0] KEY=4'b1111;
 reg [12:0] SW=0;
 wire [0:6] HEX0,HEX1,HEX2,HEX3,HEX6,HEX7;
 wire [7:0] LEDG; wire [17:0] LEDR;
 TINYPROJECT dut(KEY,clk,SW,HEX0,HEX1,HEX2,HEX3,HEX6,HEX7,LEDG,LEDR);
 string scenario; integer pulses=0;
 always @(posedge LEDG[4]) if(KEY[0]) pulses=pulses+1;
 task cycles(input integer n); repeat(n) @(negedge clk); endtask
 task check(input bit ok,input string msg); if(!ok) $fatal(1,"%s: %s sum=%0d state=%0d ticket=%b",scenario,msg,dut.sum,dut.D1.State,LEDG[4]); endtask
 task reset; KEY=4'b1110; SW=0; cycles(4); KEY=4'b1111; cycles(4); pulses=0; endtask
 task press(input integer sw); SW=13'(sw); cycles(5); KEY[3]=0; cycles(6); KEY[3]=1; cycles(50); endtask
 initial begin #1000000; $fatal(1,"timeout"); end
 initial begin
  force dut.Clk=clk; // functional tests bypass only the original divider; hardware timing tested separately
  if(!$value$plusargs("CASE=%s",scenario)) scenario="reset";
  $dumpfile({"build/",scenario,".vcd"}); $dumpvars(0,regression);
  reset;
  case(scenario)
   "reset": begin check(LEDG[4]===1'b0,"Ticket must reset to zero"); check(dut.sum===0,"balance reset"); end
   "fsm": begin press(4);press(64);check(dut.sum===1700,"first purchase");press(1);check(dut.sum===1950,"must accept next transaction after ticket");end
   "held": begin SW=1;cycles(5);KEY[3]=0;cycles(180);KEY[3]=1;cycles(50);check(dut.sum===250,"one held press must create one deposit");end
   "digit1": begin press(4);press(64);check(HEX3===7'b1001111,"digit one must light segments 1 and 2");end
   default: $fatal(1,"unknown scenario");
  endcase
  $display("PASS %s",scenario); $finish;
 end
endmodule
