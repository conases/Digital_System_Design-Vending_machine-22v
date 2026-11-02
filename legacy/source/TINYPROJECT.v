module TINYPROJECT (

  input wire [3:0] KEY,

  input wire CLOCK_50,

  input wire [12:0] SW,

  output wire [0:6] HEX0,
  output wire [0:6] HEX1,
  output wire [0:6] HEX2,
  output wire [0:6] HEX3,
  output wire [0:6] HEX6,
  output wire [0:6] HEX7,
  output wire [7:0] LEDG,   
  output wire [17:0] LEDR
  );

  wire Reset_ = ~KEY[0];

  wire IN  = ~KEY[3];
   
  

 
  
  reg [12:0] switch;
  reg[13:0] sum;
  reg [12:0] bin,sum1;
  wire sel0,sel1,sel2,sel3;
  reg [3:0] bcd0,bcd1,bcd2,bcd3,bcd6,bcd7;
  wire load,shift,loadbin,done,hap,happ,prt;
  reg Ticket;
 
  
  
     
  wire Clk ;
  
  assign LEDG[4] = Ticket;
  wire rst_ =Reset_;
  
  reg [19:0] Clk_Down = 0;

  always @(posedge CLOCK_50)

       Clk_Down = Clk_Down + 20'b1;

  assign Clk = Clk_Down[19];
 
  LAB4c D1(

  rst_,IN,

  Clk,tic,Ticket,

 
  shift,load,loadbin,done,hap,happ,prt

  );
  
      assign   sel0=(bcd0 > 4)? 1:0;      
      assign   sel1=(bcd1 > 4)? 1:0;
      assign   sel2=(bcd2 > 4)? 1:0;
      assign   sel3=(bcd3 > 4)? 1:0;
   
  
   
   always @(posedge Clk,posedge rst_ )begin      // binary shift
         if(rst_) begin
               bin <= 0; 
               sum <=0;
               sum1 <=0;
					bcd6 <=0;
					bcd7 <=0;
						end
            else if(loadbin)begin
               switch=SW;
                
               case (switch)
                  1: bin = 13'b0000111110100;
                  2: bin = 13'b0001111101000;
                  4: bin = 13'b1001110001000;
                  64: bin = 13'b0110011100100;
                  128: bin = 13'b1100111001000;
                  default: bin = 13'b0;
               endcase
                  
									end
               else if(hap)begin
						if((bin == 13'b0000111110100) ||(bin == 13'b0001111101000) ||(bin == 13'b1001110001000))
						begin
								sum<=sum+bin;
								if(sum+bin >= 13'b1111101000000)begin
										sum	<= 13'b1111101000000;
																		end
										
						end
						else if(bin == 13'b0110011100100)begin
									if(sum  >=  bin)begin
											sum <= sum -bin;
											Ticket <=1'b1;
											bcd6 <= bcd6+4'b0001;
											end
										end
						else if(bin == 13'b1100111001000)begin
									if(sum  >=  bin)begin
											sum <= sum -bin;
											Ticket <=1'b1;
											bcd7 <= bcd7+4'b0001;
											end
										end			
									
							end
									
               else if (happ)begin
                  sum1<=sum;
									end
                  
            else if(shift) begin
               sum1 <={sum1[12:0],1'b0};
									end 
							
				else if(prt == 0)begin
						Ticket <=1'b0;
					end
            
   
											end
  
  
  
   always @(posedge Clk,posedge rst_ )
   begin      
         if(rst_) begin
               bcd0 <= 0;
               bcd1 <= 0;
               bcd2 <= 0;
               bcd3 <= 0;
					
               end
            else if(hap)begin
               bcd0 <= 0;
               bcd1 <= 0;
               bcd2 <= 0;
               bcd3 <= 0;
               end
         else if(load) begin
               if(sel0) bcd0<=bcd0+3;
                  
               if(sel1) bcd1<=bcd1+3;
                  
               if(sel2) bcd2<=bcd2+3;
                  
               if(sel3) bcd3<=bcd3+3;
                  
               end
            else if(shift)begin
               bcd0 <= {bcd0[2:0],sum1[12]};
               bcd1 <= {bcd1[2:0],bcd0[3]};
               bcd2 <= {bcd2[2:0],bcd1[3]};
               bcd3 <= {bcd3[2:0],bcd2[3]};
                              
            end
            
            
   end
      
   
   


      bin7seg u0(bcd0, HEX0);
      bin7seg u1(bcd1, HEX1);
      bin7seg u2(bcd2, HEX2);
      bin7seg u3(bcd3, HEX3);
		bin7seg u4(bcd6, HEX6);
		bin7seg u5(bcd7, HEX7);
   
      
      
endmodule


module LAB4c (

  input wire rst_,IN  ,

  input wire clock,tic,Ticket,
  
  
  output reg shift,load,loadbin,done,hap,happ,prt
  

  );
  parameter  S0=3'b000, S1=3'b001, S2=3'b010, 
                 S3=3'b011, S4=3'b100, S5=3'b101,S6=3'b110,S7=3'b111;
   reg[3:0] count;
   reg [2:0] State,  NextState;

   
   // control Signal Logic
   always @(*)

   begin
      shift =1'b0;   load = 1'b0;   loadbin = 1'b0; done=1'b0; hap=1'b0;  happ=1'b0; prt=1'b0; 
      
      case (State)

         S0 :
            begin
               
               loadbin=1'b1;
            end

         S1 :
            begin
               done=1'b0;
               hap=1'b1;
               
            end
         
         S2 :
            begin
               hap=1'b0;
               happ=1'b1;
            
            end
         S3 :

            
           begin
                     happ=1'b0;
                     loadbin=1'b0;
                     load = 1'b0;
                     shift=1'b1;
                     
               end
         S4 :

            begin
               shift = 1'b0;
               if(count != 4'b1101)
                  load = 1'b1;
            end
         S5 :

            begin
               done=1'b1; 
               loadbin=1'b1;
            end
         S6: begin
					prt = 1'b1;
				end
			S7: begin
				prt =1'b0;
			end

         endcase      
   end
         
         
         always@(*)
            begin
               NextState =S0; 
               
            case (State)
               
               S0 :
                  begin
                     if(IN)
                        NextState =S1;
                     else
                        NextState =S0;
                  end
               S1 :
                  begin
                     NextState = S2;
                  
                  
                  end
                  
               S2 :
                  begin
						
                  NextState =S3;
							
                  end
                  
               S3 :
                 begin
						
							
                  NextState =S4;
					
                  end
                  
               S4 :
                 begin
                     if(count == 4'b1101)begin
                        NextState =S5;
                     end
                     else
                        NextState =S3;
                     end
                  
               S5 :
                  begin
							if(Ticket)begin
								 NextState =S6;
								end
                     else if(IN)begin
                        NextState = S1;
                        end
                     else
                        NextState =S5;
                  end
					S6:
						begin
							NextState = S7;
								
						end
					S7:
						begin
							if(IN)begin
							NextState =S1;
							end
							NextState = S7;
						end
               endcase
            end
               
         
   always @(posedge clock , posedge rst_)
  begin
         
        if (rst_) begin
              State <= S0;
              count <=0;
        end
        
       else begin
               State <= NextState;
               if (shift)
                  count <= count + 4'b0001;
                  
               if (done)begin
            count <=0;
        end
         
  end
         
end
      
   endmodule

 
 

module bin7seg (B, display);  

   input [3:0] B;

   output [0:6] display;

 

   reg [0:6] display;

 

   /*

    *       0  

    *      ---  

    *     |   |

    *    5|   |1

    *     | 6 |

    *      ---  

    *     |   |

    *    4|   |2

    *     |   |

    *      ---  

    *       3  

    */

   always @ (B)

      case (B)
         4'h0: display = 7'b0000001;
         4'h1: display = 7'b1111001;
         4'h2: display = 7'b0010010;
         4'h3: display = 7'b0000110;
         4'h4: display = 7'b1001100;
         4'h5: display = 7'b0100100;
         4'h6: display = 7'b0100000;
         4'h7: display = 7'b0001111;
         4'h8: display = 7'b0000000;
         4'h9: display = 7'b0000100;
         
         default: display = 7'b1000010;
      endcase

 

endmodule
 