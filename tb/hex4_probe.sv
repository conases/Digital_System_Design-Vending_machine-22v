`timescale 1ns/1ps
module hex4_probe;
 wire [0:6] h;
 TINYPROJECT dut(.KEY(4'b1110),.CLOCK_50(1'b0),.SW(13'b0),.HEX4(h));
 initial begin #1;if(h!==7'b0000001)$fatal(1,"HEX4 must display leading zero");$display("PASS HEX4 connection");$finish;end
endmodule
