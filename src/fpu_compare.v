`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////
// Module: fpu_compare
// Fixed-point comparator (Q16 format, 18-bit signed). Implements the
// "number comparisons" operation required by the assignment spec
// (e.g. x>y and x>=y). No iteration needed -- this is a single registered
// comparison, much simpler than the ln(x) polynomial evaluation.
//
// Note: checking "f(c) < 0" elsewhere in the design does NOT use this
// module -- that's just reading the sign bit (bit W) directly, which is
// free and needs no FPU operation at all.
//////////////////////////////////////////////////////////////////////////////
module fpu_compare #(parameter W = 17)
(
    input               clk,
    input  signed [W:0] x,
    input  signed [W:0] y,
    output reg          gt,   // x > y
    output reg          ge    // x >= y
);
    always @(posedge clk) begin
        gt <= (x > y);
        ge <= (x >= y);
    end
endmodule
