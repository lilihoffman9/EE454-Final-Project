`timescale 1ns/1ps

module tb_mlp;

    localparam IN_DIM  = 64;
    localparam OUT_DIM = 10;
    localparam XW      = 8;
    localparam ACCW    = 32;

    reg                    clk;
    reg                    rst_n;
    reg                    in_valid;
    reg  [IN_DIM*XW-1:0]   x_flat;
    wire                   out_valid;
    wire [OUT_DIM*ACCW-1:0] out_flat;

    // clock: 10 ns period
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // DUT
    mlp_top dut (
        .clk      (clk),
        .rst_n    (rst_n),
        .in_valid (in_valid),
        .x_flat   (x_flat),
        .out_valid(out_valid),
        .out_flat (out_flat)
    );

    // helper for building inputs
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

    initial begin
        $dumpfile("mlp_clk.vcd");
        $dumpvars(0, tb_mlp);

        // reset
        rst_n    = 0;
        in_valid = 0;
        x_flat   = 0;
        @(posedge clk);
        @(posedge clk);
        rst_n = 1;

        // ------------- Stimulus 1: all zeros -------------
        for (i = 0; i < IN_DIM; i = i + 1)
            stim[i] = 0;
        set_input_vector(stim);

        @(posedge clk);
        in_valid = 1;
        @(posedge clk);
        in_valid = 0;   // capture done

        // wait 1 cycle for output
        @(posedge clk);
        if (out_valid) begin
            $display("=== Stimulus 1: all zeros ===");
            for (k = 0; k < OUT_DIM; k = k + 1)
                $display("out[%0d] = %0d",
                         k, $signed(out_flat[k*ACCW +: ACCW]));
        end

        // ------------- Stimulus 2: ramp 0..63 -------------
        for (i = 0; i < IN_DIM; i = i + 1)
            stim[i] = i;
        set_input_vector(stim);

        @(posedge clk);
        in_valid = 1;
        @(posedge clk);
        in_valid = 0;

        @(posedge clk);
        if (out_valid) begin
            $display("=== Stimulus 2: ramp ===");
            for (k = 0; k < OUT_DIM; k = k + 1)
                $display("out[%0d] = %0d",
                         k, $signed(out_flat[k*ACCW +: ACCW]));
        end

        // ------------- Stimulus 3: +/- pattern -------------
        for (i = 0; i < IN_DIM; i = i + 1)
            stim[i] = (i % 2 == 0) ? 8'sd10 : -8'sd5;
        set_input_vector(stim);

        @(posedge clk);
        in_valid = 1;
        @(posedge clk);
        in_valid = 0;

        @(posedge clk);
        if (out_valid) begin
            $display("=== Stimulus 3: +/- pattern ===");
            for (k = 0; k < OUT_DIM; k = k + 1)
                $display("out[%0d] = %0d",
                         k, $signed(out_flat[k*ACCW +: ACCW]));
        end

        @(posedge clk);
        $finish;
    end

endmodule
        input signed [XW-1:0] vec [0:IN_DIM-1];
        integer idx;
        begin
            for (idx = 0; idx < IN_DIM; idx = idx + 1) begin
                x_flat[idx*XW +: XW] = vec[idx];
            end
        end
    endtask

    // A small local array just for constructing stimuli
    reg signed [XW-1:0] stim [0:IN_DIM-1];

    initial begin
        // Dump waves for viewing in Questa/ModelSim
        $dumpfile("mlp_wave.vcd");
        $dumpvars(0, tb_mlp);

        // --------------------------------------------------------------------
        // Stimulus 1: all zeros
        // --------------------------------------------------------------------
        for (i = 0; i < IN_DIM; i = i + 1)
            stim[i] = 0;

        set_input_vector(stim);

        #10; // wait some time for combinational paths to settle

        $display("=== Stimulus 1: all zeros ===");
        for (k = 0; k < OUT_DIM; k = k + 1) begin
            $display("out[%0d] = %0d",
                     k,
                     $signed(out_flat[k*ACCW +: ACCW]));
        end

        // --------------------------------------------------------------------
        // Stimulus 2: simple ramp 0,1,2,...,63 (clipped to int8)
        // --------------------------------------------------------------------
        for (i = 0; i < IN_DIM; i = i + 1)
            stim[i] = i;   // small positive test values

        set_input_vector(stim);

        #10;

        $display("=== Stimulus 2: ramp 0..63 ===");
        for (k = 0; k < OUT_DIM; k = k + 1) begin
            $display("out[%0d] = %0d",
                     k,
                     $signed(out_flat[k*ACCW +: ACCW]));
        end

        // --------------------------------------------------------------------
        // Stimulus 3: random-ish pattern (just example)
        // In practice, you can precompute one real digit sample in Python,
        // quantize it to int8 (X_q) and paste those 64 values here.
        // --------------------------------------------------------------------
        for (i = 0; i < IN_DIM; i = i + 1)
            stim[i] = (i % 2 == 0) ? 8'sd10 : -8'sd5;

        set_input_vector(stim);

        #10;

        $display("=== Stimulus 3: +/- pattern ===");
        for (k = 0; k < OUT_DIM; k = k + 1) begin
            $display("out[%0d] = %0d",
                     k,
                     $signed(out_flat[k*ACCW +: ACCW]));
        end

        // Done
        #10;
        $finish;
    end

endmodule

