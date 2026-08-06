`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/10/2025 07:36:11 PM
// Design Name: 
// Module Name: fp_multiply
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


module fp_mult(
input [7:0] a,
input [7:0] b,
output wire [7:0] y
    );

    wire sa;
    wire [2:0] Ea;
    wire [3:0] Ma;
    wire signed [5:0] ea;
    wire [4:0] mantA5;
    
    wire a_zero = (a == 8'b00000000);
    wire b_zero = (b == 8'b00000000);

    fp_decode decA (
        .x(a),
        .sign(sa),
        .exp_u(Ea),
        .man_u(Ma),
        .e(ea), // non-biased, used in calculations
        .mant5(mantA5) // implicit one attatched
    );
    
    wire sb;
    wire [2:0] Eb;
    wire [3:0] Mb;
    wire signed [5:0] eb;
    wire [4:0] mantB5;

    fp_decode decB (
        .x(b),
        .sign(sb),
        .exp_u(Eb),
        .man_u(Mb),
        .e(eb),
        .mant5(mantB5)
    );
    
    reg sign;
    reg signed [6:0] e_out;
    reg [11:0] frac_in;
    reg [9:0] prod;
    
    fp_encode enc (
        .sign_in(sign),
        .e_in(e_out),
        .mant_in(frac_in),
        .y(y)
    );
    
    always@(*) begin
   if (a_zero || b_zero) begin
    sign = 0;
    e_out   = 0;
    frac_in  = 0;
end else begin
    sign = sa^sb;
    e_out = ea + eb;
    prod = mantA5 * mantB5;
    frac_in = prod >> 4;
    end
    end
    
endmodule
