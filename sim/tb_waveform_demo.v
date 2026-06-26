`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////
// Testbench: tb_waveform_demo
// Drives root_finder_top with omega=1.0 and dumps a VCD waveform showing
// the bisection loop converging, for documentation screenshots.
//////////////////////////////////////////////////////////////////////////////
module tb_waveform_demo;
    parameter W = 17;
    localparam real SCALE = 65536.0;

    reg               Clock, Reset, Start;
    reg  signed [W:0] omega, epsilon;
    reg        [15:0] Nmax;
    wire signed [W:0] x_hat;
    wire              error, Ready;

    root_finder_top #(W) dut (
        .Clock(Clock), .Reset(Reset), .Start(Start),
        .omega(omega), .epsilon(epsilon), .Nmax(Nmax),
        .x_hat(x_hat), .error(error), .Ready(Ready)
    );

    always #5 Clock = ~Clock;

    initial begin
        $dumpfile("sim/waveform_demo.vcd");
        $dumpvars(0, tb_waveform_demo);

        Clock = 0; Reset = 1; Start = 0;
        omega   = 18'sd65536; // 1.0
        epsilon = 18'sd66;    // ~0.001
        Nmax    = 16'd20;

        repeat (3) @(posedge Clock);
        Reset = 0;
        @(posedge Clock);
        Start = 1;
        @(posedge Clock);
        Start = 0;

        wait (Ready == 1'b1);
        @(posedge Clock);
        $display("x_hat=%f error=%b", $itor(x_hat)/SCALE, error);
        $finish;
    end
endmodule
