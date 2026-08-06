`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/10/2025 07:18:00 PM
// Design Name: 
// Module Name: fp_encode
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


module fp_encode (
    input  wire sign_in,
    input  wire signed [6:0] e_in,
    input  wire [11:0] mant_in,
    output reg  [7:0]  y
);

    reg signed [7:0] e;
    reg [11:0] mant;
    reg [4:0]  mant5;
    reg [2:0]  E;
    reg s;
    reg signed [7:0] Eb;
    integer i;

    always @(*) begin
        s = sign_in;
        e = e_in;
        mant = mant_in;

        if (mant == 12'd0) begin
            y = 8'b00000000;
        end else begin

            for (i = 0; i < 12; i = i + 1) begin
                if (mant >= 12'd32) begin
                    mant = mant >> 1;
                    e    = e + 1;
                end
            end

       
            for (i = 0; i < 12; i = i + 1) begin
                if (mant != 0 && mant < 12'd16) begin
                    mant = mant << 1;
                    e    = e - 1;
                end
            end

           
            if (mant == 12'd0) begin
                y = 8'b00000000;
            end else begin

                Eb = e + 3;

                if (Eb < 0) begin
                    y = 8'b00000000;
                end
                else if (Eb > 7) begin
                    y = {s, 3'b111, 4'b1111};
                end else begin
                    // pack
                    mant5 = mant[4:0];
                    E     = Eb[2:0];
                    y     = {s, E, mant5[3:0]};
                end

            end
        end
    end
endmodule
