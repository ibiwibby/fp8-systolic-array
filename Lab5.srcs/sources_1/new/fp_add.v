`timescale 1ns / 1ps

module fp_add (
    input  wire [7:0] a,
    input  wire [7:0] b,
    output wire [7:0] y
);
    // Zero detect
    wire a_zero = (a == 8'b00000000);
    wire b_zero = (b == 8'b00000000);

    // Decode A
    wire        sa;
    wire [2:0]  Ea;
    wire [3:0]  Ma;
    wire signed [5:0] ea;       // unbiased exponent
    wire [4:0]  mantA5;         // 1.MA as 5-bit integer [16..31]
    fp_decode decA (
        .x(a),
        .sign(sa),
        .exp_u(Ea),
        .man_u(Ma),
        .e(ea),
        .mant5(mantA5)
    );

    // Decode B
    wire        sb;
    wire [2:0]  Eb;
    wire [3:0]  Mb;
    wire signed [5:0] eb;
    wire [4:0]  mantB5;
    fp_decode decB (
        .x(b),
        .sign(sb),
        .exp_u(Eb),
        .man_u(Mb),
        .e(eb),
        .mant5(mantB5)
    );

    // To encoder
    reg              sign_out;
    reg signed [6:0] e_out;
    reg [11:0]       mant_in;

    fp_encode enc (
        .sign_in(sign_out),
        .e_in(e_out),
        .mant_in(mant_in),
        .y(y)
    );

    // Working regs
    reg signed [6:0] e_big, e_small;
    reg [11:0]       m_big, m_small;
    reg              s_big, s_small;

    reg [11:0]       m_small_aligned;
    reg signed [6:0] delta;

    reg [11:0]       sum;
    reg              s_res;

    always @(*) begin
        // Defaults
        sign_out = 1'b0;
        e_out    = 7'd0;
        mant_in  = 12'd0;

        // Case 1: both zero
        if (a_zero && b_zero) begin
            // keep defaults
        end

        // Case 2: a == 0 → return b
        else if (a_zero) begin
            sign_out = sb;
            e_out    = eb;
            mant_in  = {7'd0, mantB5};   // <<< FIXED: mantissa in LOW bits
        end

        // Case 3: b == 0 → return a
        else if (b_zero) begin
            sign_out = sa;
            e_out    = ea;
            mant_in  = {7'd0, mantA5};   // <<< FIXED: mantissa in LOW bits
        end

        // Case 4: normal add/sub
        else begin
            // Choose the larger exponent as "big"
            if (ea >= eb) begin
                e_big    = ea;
                e_small  = eb;
                m_big    = {7'd0, mantA5};  // <<< FIXED scaling
                m_small  = {7'd0, mantB5};  // <<< FIXED scaling
                s_big    = sa;
                s_small  = sb;
            end else begin
                e_big    = eb;
                e_small  = ea;
                m_big    = {7'd0, mantB5};  // <<< FIXED scaling
                m_small  = {7'd0, mantA5};  // <<< FIXED scaling
                s_big    = sb;
                s_small  = sa;
            end

            // Align smaller mantissa (right shift by exponent delta)
            delta = e_big - e_small;
            if (delta >= 12)
                m_small_aligned = 12'd0;
            else
                m_small_aligned = m_small >> delta;

            // Add/sub depending on signs
            if (s_big == s_small) begin
                sum   = m_big + m_small_aligned;
                s_res = s_big;
            end else begin
                if (m_big >= m_small_aligned) begin
                    sum   = m_big - m_small_aligned;
                    s_res = s_big;
                end else begin
                    sum   = m_small_aligned - m_big;
                    s_res = s_small;
                end
            end

            // Cancellation to zero
            if (sum == 12'd0) begin
                sign_out = 1'b0;
                e_out    = 7'd0;
                mant_in  = 12'd0;
            end else begin
                // Hand to encoder; it will normalize and clamp
                sign_out = s_res;
                e_out    = e_big;
                mant_in  = sum;           // already in the expected scale
            end
        end
    end

endmodule
