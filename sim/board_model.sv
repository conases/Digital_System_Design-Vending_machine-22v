`default_nettype none
module board_model #(parameter integer DIV_BITS=20)(
 input wire CLOCK_50,input wire [3:0] KEY,input wire [12:0] SW,
 /* verilator lint_off ASCRANGE */
 output wire [0:6] HEX0,HEX1,HEX2,HEX3,HEX4,HEX6,HEX7,
 /* verilator lint_on ASCRANGE */
 output wire [7:0] LEDG,output wire [17:0] LEDR,
 output wire [13:0] balance,output wire [2:0] state,
 output wire [3:0] count6,count7,output wire issue,ready,pending,ce
);
 TINYPROJECT #(.DIV_BITS(DIV_BITS)) dut(
 .CLOCK_50(CLOCK_50),.KEY(KEY),.SW(SW),.HEX0(HEX0),.HEX1(HEX1),.HEX2(HEX2),
 .HEX3(HEX3),.HEX4(HEX4),.HEX6(HEX6),.HEX7(HEX7),.LEDG(LEDG),.LEDR(LEDR));
 assign balance=dut.sum;assign state=dut.D1.State;
 assign count6=dut.bcd6;assign count7=dut.bcd7;
 assign issue=dut.issue;assign ready=dut.ready;assign pending=dut.pending;assign ce=dut.ce;
endmodule
`default_nettype wire
