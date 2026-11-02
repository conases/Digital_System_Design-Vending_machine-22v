`timescale 1ns/1ps
module board_regression;
 reg clk=0;always #10 clk=~clk;
 reg [3:0] KEY=15;reg [12:0] SW=0;
 wire [0:6] h0,h1,h2,h3,h4,h6,h7;
 wire [7:0] g;wire [17:0] r;
 TINYPROJECT #(.DIV_BITS(2)) dut(.CLOCK_50(clk),.KEY(KEY),.SW(SW),.HEX0(h0),.HEX1(h1),.HEX2(h2),.HEX3(h3),.HEX4(h4),.HEX6(h6),.HEX7(h7),.LEDG(g),.LEDR(r));
 integer fd,rc,id,sw,b,c6,c7,issue,issues=0,before_issues,total=0;
 reg [0:6] seg [0:9];
 task cycles(input integer n);repeat(n)@(negedge clk);endtask
 always @(negedge clk)if(dut.issue)issues=issues+1;
 task validate;
  if(dut.sum!==b || dut.bcd6!==c6 || dut.bcd7!==c7 ||
    h0!==seg[b%10] || h1!==seg[(b/10)%10] || h2!==seg[(b/100)%10] || h3!==seg[(b/1000)%10] || h4!==seg[0] || h6!==seg[c6] || h7!==seg[c7] ||
    (^{g,r,h0,h1,h2,h3,h4,h6,h7})===1'bx)
   $fatal(1,"oracle mismatch scenario=%0d SW=%0d expected=%0d actual=%0d c6=%0d c7=%0d",id,sw,b,dut.sum,dut.bcd6,dut.bcd7);
 endtask
 initial begin
  seg[0]=7'b0000001;seg[1]=7'b1001111;seg[2]=7'b0010010;seg[3]=7'b0000110;seg[4]=7'b1001100;
  seg[5]=7'b0100100;seg[6]=7'b0100000;seg[7]=7'b0001111;seg[8]=7'b0000000;seg[9]=7'b0000100;
  fd=$fopen("build/oracle.txt","r");if(!fd)$fatal(1,"oracle fixture missing");
  while(!$feof(fd))begin
   rc=$fscanf(fd,"%d %d %d %d %d %d\n",id,sw,b,c6,c7,issue);
   if(rc!=6)$fatal(1,"bad oracle fixture");
   if(sw==-1)begin KEY=14;SW=0;cycles(5);KEY=15;cycles(8);end
   else begin
    SW=13'(sw);cycles(8);before_issues=issues;
    KEY[3]=0;cycles(6);KEY[3]=1;cycles(220);
    if(issues-before_issues!=issue)$fatal(1,"issue count scenario=%0d got=%0d expected=%0d",id,issues-before_issues,issue);
   end
   validate;total=total+1;
  end
  // 거래 중 reset: pending/FSM/잔액/표시/카운트 모두 초기화.
  SW=4;cycles(8);KEY[3]=0;cycles(6);KEY=14;cycles(6);KEY=15;SW=0;cycles(8);
  b=0;c6=0;c7=0;validate;
  $display("PASS Icarus board oracle %0d steps, four-state outputs and reset during transaction",total);$finish;
 end
 initial begin #100000000;$fatal(1,"timeout");end
endmodule
