`default_nettype none
module LAB4c (
 input wire rst_,IN,clock,enable,Ticket,
 output reg shift,load,loadbin,done,hap,happ,prt
);
 localparam S0=3'd0,S1=3'd1,S2=3'd2,S3=3'd3,S4=3'd4,S5=3'd5,S6=3'd6,S7=3'd7;
 reg [3:0] count;
 reg [2:0] State,NextState;
 always @* begin
  shift=0;load=0;loadbin=0;done=0;hap=0;happ=0;prt=0;
  case(State)
   S0:loadbin=1;
   S1:hap=1;
   S2:happ=1;
   S3:shift=1;
   S4:if(count!=13)load=1;
   S5:begin done=1;loadbin=1;end
   S6:prt=1;
   S7:loadbin=1;
   default:begin end
  endcase
 end
 always @* begin
  NextState=S0;
  case(State)
   S0:if(IN)NextState=S1;else NextState=S0;
   S1:NextState=S2;
   S2:NextState=S3;
   S3:NextState=S4;
   S4:if(count==13)NextState=S5;else NextState=S3;
   S5:if(Ticket)NextState=S6;else if(IN)NextState=S1;else NextState=S5;
   S6:NextState=S7;
   S7:if(IN)NextState=S1;else NextState=S7;
   default:NextState=S0;
  endcase
 end
 always @(posedge clock or posedge rst_) begin
  if(rst_)begin State<=S0;count<=0;end
  else if(enable)begin
   State<=NextState;
   if(shift)count<=count+1'b1;
   if(done)count<=0;
  end
 end
endmodule
`default_nettype wire
