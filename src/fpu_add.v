`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////
// Module: fpu_add
// Fixed-point adder (Q16 format, 18-bit signed: 2 integer/sign bits + 16
// fractional bits, matching the scaling already used in the ln(x) module).
//
// Registered (1 clock cycle latency), consistent with every other FPU
// operation in this design -- the MAU always allocates at least one
// state/cycle for an FPU result to become valid.
//////////////////////////////////////////////////////////////////////////////
module fpu_add #(parameter W = 17)
(
    input               clk,
    input  signed [W:0] a,
    input  signed [W:0] b,
    output reg signed [W:0] sum
);
    always @(posedge clk) begin
        sum <= a + b; // both operands share the same Q16 scale, so plain
                      // two's-complement addition works directly
    end
endmodule
