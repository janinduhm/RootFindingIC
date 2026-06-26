`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////
// Module: fpu_divby2
// Fixed-point divide-by-2 (Q16 format, 18-bit signed).
// Dividing a fixed-point number by 2 is just an arithmetic right shift by 1
// bit -- no iteration needed, matching the same reasoning we use for the
// >>>16 rescaling step in the ln(x) approximation.
//
// Registered (1 clock cycle latency), consistent with every other FPU
// operation in this design -- this is what makes RECOMPUTE a clean 2-cycle
// state (1 cycle add, 1 cycle divide-by-2).
//////////////////////////////////////////////////////////////////////////////
module fpu_divby2 #(parameter W = 17)
(
    input               clk,
    input  signed [W:0] a,
    output reg signed [W:0] result
);
    always @(posedge clk) begin
        result <= a >>> 1; // arithmetic shift preserves sign for negatives
    end
endmodule
