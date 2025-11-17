`timescale 1ns/1ps

module tb_mlp;

    // ------------------------------------------------------------------------
    // Parameters (must match mlp_top)
    // ------------------------------------------------------------------------
    localparam IN_DIM  = 64;
    localparam H_DIM   = 8;
    localparam OUT_DIM = 10;
    localparam XW      = 8;
    localparam ACCW    = 32;

    // ------------------------------------------------------------------------
    // DUT I/O
    // ------------------------------------------------------------------------
    reg                     clk;
    reg                     rst_n;
    reg                     in_valid;
    reg  [IN_DIM*XW-1:0]    x_flat;
    wire                    out_valid;
    wire [OUT_DIM*ACCW-1:0] out_flat;

    // ------------------------------------------------------------------------
    // Instantiate DUT
    // ------------------------------------------------------------------------
    mlp_top #(
        .IN_DIM (IN_DIM),
        .H_DIM  (H_DIM),
        .OUT_DIM(OUT_DIM),
        .XW     (XW),
        .WW     (8),
        .ACCW   (ACCW)
    ) dut (
        .clk      (clk),
        .rst_n    (rst_n),
        .in_valid (in_valid),
        .x_flat   (x_flat),
        .out_valid(out_valid),
        .out_flat (out_flat)
    );

    // ------------------------------------------------------------------------
    // Clock generation: 10 ns period
    // ------------------------------------------------------------------------
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    // ------------------------------------------------------------------------
    // Helper storage and task to build input vectors
    // ------------------------------------------------------------------------
    reg signed [XW-1:0] stim [0:IN_DIM-1];
    integer i, k;

    task set_input_vector;
        input signed [XW-1:0] vec [0:IN_DIM-1];
        integer idx;
        begin
            for (idx = 0; idx < IN_DIM; idx = idx + 1)
                x_flat[idx*XW +: XW] = vec[idx];
        end
    endtask

    // ------------------------------------------------------------------------
    // Test sequence
    // ------------------------------------------------------------------------
    initial begin
        // VCD (optional – good for GTKWave; ModelSim can ignore)
        $dumpfile("mlp_clk.vcd");
        $dumpvars(0, tb_mlp);

        // Reset
        rst_n    = 1'b0;
        in_valid = 1'b0;
        x_flat   = {IN_DIM*XW{1'b0}};

        @(posedge clk);
        @(posedge clk);
        rst_n = 1'b1;      // deassert reset

        // ================= Stimulus 1: all zeros =================
        for (i = 0; i < IN_DIM; i = i + 1)
            stim[i] = 0;
        set_input_vector(stim);

        @(posedge clk);
        in_valid = 1'b1;   // present zeros
        @(posedge clk);
        in_valid = 1'b0;

        // wait a couple of cycles for DUT to produce outputs
        @(posedge clk);
        @(posedge clk);

        $display("=== Stimulus 1: all zeros ===");
        for (k = 0; k < OUT_DIM; k = k + 1)
            $display("out[%0d] = %0d",
                     k, $signed(out_flat[k*ACCW +: ACCW]));

        // ================= Stimulus 2: ramp 0..63 =================
        for (i = 0; i < IN_DIM; i = i + 1)
            stim[i] = i;   // simple ramp
        set_input_vector(stim);

        @(posedge clk);
        in_valid = 1'b1;
        @(posedge clk);
        in_valid = 1'b0;

        @(posedge clk);
        @(posedge clk);

        $display("=== Stimulus 2: ramp 0..63 ===");
        for (k = 0; k < OUT_DIM; k = k + 1)
            $display("out[%0d] = %0d",
                     k, $signed(out_flat[k*ACCW +: ACCW]));

        // ================= Stimulus 3: +/- pattern =================
        for (i = 0; i < IN_DIM; i = i + 1)
            stim[i] = (i % 2 == 0) ? 8'sd10 : -8'sd5;
        set_input_vector(stim);

        @(posedge clk);
        in_valid = 1'b1;
        @(posedge clk);
        in_valid = 1'b0;

        @(posedge clk);
        @(posedge clk);

        $display("=== Stimulus 3: +/- pattern ===");
        for (k = 0; k < OUT_DIM; k = k + 1)
            $display("out[%0d] = %0d",
                     k, $signed(out_flat[k*ACCW +: ACCW]));

        // Done
        @(posedge clk);
        $finish;
    end

endmodule
