`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/10/2025 08:57:04 PM
// Design Name: 
// Module Name: mac_fp
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


module mac_fp(
    input  wire clk,
    input  wire reset, 
    input  wire [7:0]  a_in,
    input  wire [7:0]  b_in,
    output reg  [7:0]  a_out,
    output reg  [7:0]  b_out,
    output reg  [7:0]  acc_out     // running sum (C[i][j] after 7 cycles)
    );
    
    wire [7:0] prod;
    wire [7:0] sum;
    fp_mult u_mul (
        .a(a_in),
        .b(b_in),
        .y(prod)
    );
    fp_add  u_add (
        .a(acc_out),
        .b(prod),
        .y(sum)
    );
    
    always @(posedge clk) begin
        if (reset) begin
            a_out  <= 8'h00;
            b_out  <= 8'h00;
            acc_out<= 8'h00;  // FP8 zero
        end else begin
            a_out  <= a_in;   // move right
            b_out  <= b_in;   // move down
            acc_out<= sum;    // A <- A + (a*b)
        end
    end

endmodule
