`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////
// Module: fpu_ln
// Fixed-point ln(x) approximation (Q16 format, 18-bit signed), using a
// 5th-order Chebyshev polynomial approximation evaluated via Horner's
// method. Core logic carried over unchanged from the original verified
// implementation (ln.v, Dec 2019) -- only renamed/commented for clarity
// and consistency with the rest of this design.
//
// 2-cycle latency: cycle 1 registers the input (Store), cycle 2 computes
// the full Horner evaluation and registers the result (SOP). The MAU must
// allocate two states/cycles (EVAL_LN1, EVAL_LN2) to use this module.
//////////////////////////////////////////////////////////////////////////////
module fpu_ln #(
    parameter N = 5, // number of polynomial coefficients - 1
    parameter W = 17 // bit width - 1
)
(
    input               clk,
    input  signed [W:0] x_in,
    output reg signed [W:0] f_out
);
    reg signed [W:0] x;          // registered input (Store stage)
    wire signed [W:0] p [0:5];    // Chebyshev coefficients (Q16 fixed-point)
    reg  signed [W:0] s [0:5];    // Horner partial-sum registers

    // Chebyshev polynomial coefficients for ln(x+1) approximation,
    // pre-scaled by 2^16 for fixed-point representation:
    // f(x) = (1 + 65481x - 32093x^2 + 18601x^3 - 8517x^4 + 1954x^5) / 65536
    assign p[0] = 18'sd1;
    assign p[1] = 18'sd65481;
    assign p[2] = -18'sd32093;
    assign p[3] = 18'sd18601;
    assign p[4] = -18'sd8517;
    assign p[5] = 18'sd1954;

    // Stage 1 (Store): capture the input
    always @(posedge clk) begin : Store
        x <= x_in;
    end

    // Stage 2 (SOP -- "sum of products"): evaluate the polynomial via
    // Horner's method, reusing one multiplier across N+1 terms instead of
    // computing each power of x separately.
    always @(posedge clk) begin : SOP
        integer k;
        reg signed [35:0] slv;
        s[N] = p[N];

        for (k = N-1; k >= 0; k = k-1) begin
            slv  = x * s[k+1];        // wide intermediate product
            s[k] = (slv >>> 16) + p[k]; // rescale back to Q16, add next term
        end
        f_out <= s[0];
    end
endmodule
