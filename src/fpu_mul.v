`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////
// Module: fpu_mul
// Fixed-point multiplier (Q16 format, 18-bit signed in, 18-bit signed out).
// Multiplying two Q16 numbers gives a result scaled by 2^32 (doubly scaled),
// so we rescale back down by >>>16 -- the same fixed-point technique used
// inside the ln(x) Horner-method evaluation.
//
// The product is computed into a WIDE intermediate (36 bits, same pattern
// as fpu_ln.v's `slv`) before shifting. Without this, `(a*b)` would be
// computed in the context of the 18-bit `result` target and silently
// truncated to 18 bits BEFORE the >>>16 shift, discarding exactly the bits
// the shift needs -- a real bug caught via simulation (e.g. 1.0 * 0.692
// came out as ~0 instead of 0.692).
//
// Registered (1 clock cycle latency), consistent with every other FPU
// operation in this design.
//////////////////////////////////////////////////////////////////////////////
module fpu_mul #(parameter W = 17)
(
    input               clk,
    input  signed [W:0] a,
    input  signed [W:0] b,
    output reg signed [W:0] result
);
    always @(posedge clk) begin
        reg signed [2*(W+1)-1:0] wide_product;
        wide_product = a * b;           // full-width product, no truncation
        result <= wide_product >>> 16;  // rescale Q32 back down to Q16
    end
endmodule
