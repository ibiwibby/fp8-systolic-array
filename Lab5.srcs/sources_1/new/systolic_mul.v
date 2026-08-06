`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/10/2025 09:00:55 PM
// Design Name: 
// Module Name: systolic_mul
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


module systolic_mul(
    input  wire clk,
    input  wire reset,
    input  wire start,

    input  wire [7:0] a00, a01, a02,
    input  wire [7:0] a10, a11, a12,
    input  wire [7:0] a20, a21, a22,

    input  wire [7:0] b00, b01, b02,
    input  wire [7:0] b10, b11, b12,
    input  wire [7:0] b20, b21, b22,

    output wire [7:0] M1_out, M2_out, M3_out,
    output wire [7:0] M4_out, M5_out, M6_out,
    output wire [7:0] M7_out, M8_out, M9_out,

    output reg done
    );
    
reg [2:0] cnt; // keep track of total cycles, should finish after 7 cycles
reg running;

always @(posedge clk) begin
    if (reset) begin
        cnt <= 3'd0;
        running <= 1'b0;
        done <= 1'b0;
    end else begin
        done <= 1'b0;

        if (start && !running) begin
            running <= 1'b1;
            cnt <= 3'd1;
        end else if (running) begin
            cnt <= cnt + 3'd1;
            if (cnt == 3'd7) begin
                running <= 1'b0;
                done <= 1'b1;
            end
        end
    end
end

reg [7:0] a_row0, a_row1, a_row2;
reg [7:0] b_col0, b_col1, b_col2;

always @(posedge clk) begin
    if (reset) begin
        a_row0 <= 8'h00;
        a_row1 <= 8'h00;
        a_row2 <= 8'h00;

        b_col0 <= 8'h00;
        b_col1 <= 8'h00;
        b_col2 <= 8'h00;
    end else begin
        case (cnt)
            3'd1: a_row0 <= a00;
            3'd2: a_row0 <= a01;
            3'd3: a_row0 <= a02;
            default: a_row0 <= 8'h00;
        endcase

        case (cnt)
            3'd2: a_row1 <= a10;
            3'd3: a_row1 <= a11;
            3'd4: a_row1 <= a12;
            default: a_row1 <= 8'h00;
        endcase

        case (cnt)
            3'd3: a_row2 <= a20;
            3'd4: a_row2 <= a21;
            3'd5: a_row2 <= a22;
            default: a_row2 <= 8'h00;
        endcase

        case (cnt)
            3'd1: b_col0 <= b00;
            3'd2: b_col0 <= b10;
            3'd3: b_col0 <= b20;
            default: b_col0 <= 8'h00;
        endcase

        case (cnt)
            3'd2: b_col1 <= b01;
            3'd3: b_col1 <= b11;
            3'd4: b_col1 <= b21;
            default: b_col1 <= 8'h00;
        endcase

        case (cnt)
            3'd3: b_col2 <= b02;
            3'd4: b_col2 <= b12;
            3'd5: b_col2 <= b22;
            default: b_col2 <= 8'h00;
        endcase

    end
end

// Top row
wire [7:0] a00_to_01, a01_to_02;
wire [7:0] b00_to_10, b01_to_11, b02_to_12;

// Middle row
wire [7:0] a10_to_11, a11_to_12;
wire [7:0] b10_to_20, b11_to_21, b12_to_22;

// Bottom row
wire [7:0] a20_to_21, a21_to_22;

wire [7:0] acc00, acc01, acc02;
wire [7:0] acc10, acc11, acc12;
wire [7:0] acc20, acc21, acc22;

mac_fp M00 (
    .clk(clk), .reset(reset),
    .a_in(a_row0), .b_in(b_col0),
    .a_out(a00_to_01), .b_out(b00_to_10),
    .acc_out(acc00)
);

mac_fp M01 (
    .clk(clk), .reset(reset),
    .a_in(a00_to_01), .b_in(b_col1),
    .a_out(a01_to_02), .b_out(b01_to_11),
    .acc_out(acc01)
);

mac_fp M02 (
    .clk(clk), .reset(reset),
    .a_in(a01_to_02), .b_in(b_col2),
    .a_out(), .b_out(b02_to_12),
    .acc_out(acc02)
);


// Second row
mac_fp M10 (
    .clk(clk), .reset(reset),
    .a_in(a_row1), .b_in(b00_to_10),
    .a_out(a10_to_11), .b_out(b10_to_20),
    .acc_out(acc10)
);

mac_fp M11 (
    .clk(clk), .reset(reset),
    .a_in(a10_to_11), .b_in(b01_to_11),
    .a_out(a11_to_12), .b_out(b11_to_21),
    .acc_out(acc11)
);

mac_fp M12 (
    .clk(clk), .reset(reset),
    .a_in(a11_to_12), .b_in(b02_to_12),
    .a_out(), .b_out(b12_to_22),
    .acc_out(acc12)
);


// Third row
mac_fp M20 (
    .clk(clk), .reset(reset),
    .a_in(a_row2), .b_in(b10_to_20),
    .a_out(a20_to_21), .b_out(),
    .acc_out(acc20)
);

mac_fp M21 (
    .clk(clk), .reset(reset),
    .a_in(a20_to_21), .b_in(b11_to_21),
    .a_out(a21_to_22), .b_out(),
    .acc_out(acc21)
);

mac_fp M22 (
    .clk(clk), .reset(reset),
    .a_in(a21_to_22), .b_in(b12_to_22),
    .a_out(), .b_out(),
    .acc_out(acc22)
);

assign M1_out = acc00; // C00
assign M2_out = acc01; // C01
assign M3_out = acc02; // C02

assign M4_out = acc10; // C10
assign M5_out = acc11; // C11
assign M6_out = acc12; // C12

assign M7_out = acc20; // C20
assign M8_out = acc21; // C21
assign M9_out = acc22; // C22

endmodule