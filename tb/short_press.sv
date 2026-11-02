`timescale 1ns/1ps
module short_press;
 reg clk=0;always #10 clk=~clk;
 reg [3:0] KEY=15;reg [12:0] SW=0;
 TINYPROJECT dut(.KEY(KEY),.CLOCK_50(clk),.SW(SW));
 initial begin
  $dumpfile("build/short.vcd");
`ifdef ORIGINAL
  $dumpvars(0,dut.sum,dut.D1.State);
`else
  $dumpvars(0,dut.sum,dut.pending,dut.D1.State,dut.ce);
`endif
  KEY=14;repeat(5)@(negedge clk);KEY=15;
  SW=1;repeat(5)@(negedge clk);KEY[3]=0;repeat(5)@(negedge clk);KEY[3]=1;
  repeat(2200000)@(negedge clk);
  if(dut.sum!==500)$fatal(1,"short press lost: expected 500 got %0d",dut.sum);
  $display("PASS short hardware input capture");$finish;
 end
 initial begin #50000000;$fatal(1,"timeout");end
endmodule
