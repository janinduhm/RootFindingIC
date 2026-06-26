`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////
// Testbench: tb_root_finder
// Drives root_finder_top with several omega values and checks that it
// converges to the corresponding root of f(x) = omega*ln(x+1) + (x-1) = 0.
// Expected roots were independently computed by hand (real arithmetic),
// not derived from this design, to make this an honest check.
//
// omega must stay within our Q16 format's representable range, (-2, +2)
// exclusive of the upper bound: 18 bits = 1 sign bit + 1 integer bit + 16
// fractional bits, so +2.0 itself (raw 131072 = 2^17) overflows and wraps
// to -2.0 in two's complement. Caught via simulation: testing omega=2.0
// silently became omega=-2.0, which made f(c) negative everywhere and the
// bisection loop ran to Nmax without converging.
//
// Also includes one deliberately under-resourced case (Nmax too small to
// reach epsilon) to confirm the error/ERROR_ST exit path itself works, not
// just the converging path.
//////////////////////////////////////////////////////////////////////////////
module tb_root_finder;
    parameter W = 17;
    localparam real SCALE = 65536.0;
    localparam real TOL   = 0.01; // Q16 quantization + Chebyshev approx error

    reg               Clock;
    reg               Reset;
    reg               Start;
    reg  signed [W:0] omega;
    reg  signed [W:0] epsilon;
    reg        [15:0] Nmax;
    wire signed [W:0] x_hat;
    wire              error;
    wire              Ready;

    root_finder_top #(W) dut (
        .Clock(Clock), .Reset(Reset), .Start(Start),
        .omega(omega), .epsilon(epsilon), .Nmax(Nmax),
        .x_hat(x_hat), .error(error), .Ready(Ready)
    );

    always #5 Clock = ~Clock; // 10ns clock period

    real x_hat_real;
    integer pass_count, fail_count;

    task run_case(input real omega_real, input real expected_root, input integer nmax_val, input expect_error);
        begin
            omega   = $rtoi(omega_real * SCALE);
            epsilon = 18'sd66; // ~0.001
            Nmax    = nmax_val;

            Reset = 1;
            repeat (3) @(posedge Clock);
            Reset = 0;
            @(posedge Clock);
            Start = 1;
            @(posedge Clock);
            Start = 0;

            wait (Ready == 1'b1);
            @(posedge Clock);

            x_hat_real = $itor(x_hat) / SCALE;
            if (expect_error) begin
                if (error) begin
                    $display("PASS: omega=%f Nmax=%0d correctly reported error (did not converge in time)",
                        omega_real, nmax_val);
                    pass_count = pass_count + 1;
                end else begin
                    $display("FAIL: omega=%f Nmax=%0d expected error flag, but converged to x_hat=%f",
                        omega_real, nmax_val, x_hat_real);
                    fail_count = fail_count + 1;
                end
            end else if (error) begin
                $display("FAIL: omega=%f did not converge (error flag set)", omega_real);
                fail_count = fail_count + 1;
            end else if ((x_hat_real - expected_root > TOL) || (expected_root - x_hat_real > TOL)) begin
                $display("FAIL: omega=%f x_hat=%f expected=%f (diff=%f)",
                    omega_real, x_hat_real, expected_root, x_hat_real - expected_root);
                fail_count = fail_count + 1;
            end else begin
                $display("PASS: omega=%f x_hat=%f expected=%f (diff=%f)",
                    omega_real, x_hat_real, expected_root, x_hat_real - expected_root);
                pass_count = pass_count + 1;
            end
        end
    endtask

    initial begin
        Clock = 0;
        Start = 0;
        pass_count = 0;
        fail_count = 0;

        // Root of f(x)=omega*ln(x+1)+(x-1)=0, found by hand for each omega:
        run_case(1.0, 0.5571, 20, 1'b0);
        run_case(1.5, 0.4465, 20, 1'b0);
        run_case(0.5, 0.7270, 20, 1'b0);
        // Deliberately too few iterations to reach epsilon=0.001 from the
        // [0,1] initial bracket (each iteration halves the interval; 3
        // iterations only gets to width 0.125) -- exercises ERROR_ST.
        run_case(1.0, 0.5571, 3, 1'b1);

        $display("---- %0d passed, %0d failed ----", pass_count, fail_count);
        $finish;
    end
endmodule
