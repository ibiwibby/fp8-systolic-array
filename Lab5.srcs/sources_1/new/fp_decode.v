`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/10/2025 07:06:53 PM
// Design Name: 
// Module Name: fp_decode
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module fp_decode(
input wire [7:0] x,
output reg sign,
output reg  [2:0] exp_u,
output reg  [3:0] man_u,
output reg [5:0] e,
output reg [4:0] mant5
    );

     always @(*) begin
        sign = x[7];
        exp_u = x[6:4];
        man_u = x[3:0];
            e = exp_u - 3; // acutal non-biased exponent
            mant5 = {1'b1, man_u};  // normalized fraction
        end
             
endmodule
