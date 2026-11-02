`default_nettype none
/* verilator lint_off ASCRANGE */
module bin7seg (B, display);  

   input [3:0] B;

   output [0:6] display;

 

   reg [0:6] display;

 

   /* verilator lint_on ASCRANGE */

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
         4'h1: display = 7'b1001111;
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
 
`default_nettype wire
