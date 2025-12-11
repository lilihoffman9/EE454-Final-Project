`timescale 1ns/1ps

module tb_FinalProjectP1;

    // ========================================================================
    // Parameters
    // ========================================================================
    localparam IN_DIM  = 32;
    localparam H_DIM   = 4;
    localparam OUT_DIM = 5;
    localparam XW      = 4;
    localparam WW      = 8;
    localparam ACCW    = 16;

    // ========================================================================
    // DUT Signals
    // ========================================================================
    reg                     clk;
    reg                     rst_n;
    reg                     in_valid;
    reg  [IN_DIM*XW-1:0]    x_flat;
    wire                    out_valid;
    wire [OUT_DIM*ACCW-1:0] out_flat;

    // ========================================================================
    // Instantiate DUT
    // ========================================================================
    FinalProjectP1 #(
        .IN_DIM (IN_DIM),
        .H_DIM  (H_DIM),
        .OUT_DIM(OUT_DIM),
        .XW     (XW),
        .WW     (WW),
        .ACCW   (ACCW)
    ) dut (
        .clk      (clk),
        .rst_n    (rst_n),
        .in_valid (in_valid),
        .x_flat   (x_flat),
        .out_valid(out_valid),
        .out_flat (out_flat)
    );

    // ========================================================================
    // Clock generation: 10 ns period (100 MHz)
    // ========================================================================
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    // ========================================================================
    // Helper arrays and tasks
    // ========================================================================
    reg signed [XW-1:0] stim [0:IN_DIM-1];
    integer i, k;

    // Task to pack input vector into flat signal
    task set_input_vector;
        input signed [XW-1:0] vec [0:IN_DIM-1];
        integer idx;
        begin
            for (idx = 0; idx < IN_DIM; idx = idx + 1)
                x_flat[idx*XW +: XW] = vec[idx];
        end
    endtask

    // Task to send one input and wait for output
    task send_vector_and_check;
        input [80*8-1:0] test_name;  // string
        begin
            $display("\n=== %s ===", test_name);
            
            @(posedge clk);
            in_valid = 1'b1;
            @(posedge clk);
            in_valid = 1'b0;
            
            // Wait for out_valid to go high
            wait(out_valid);
            @(posedge clk);  // Wait one more cycle to sample the output
            
            $display("✓ out_valid asserted");
            for (k = 0; k < OUT_DIM; k = k + 1)
                $display("  out[%0d] = %0d", k, $signed(out_flat[k*ACCW +: ACCW]));
            
            @(posedge clk);  // Extra cycle for spacing
        end
    endtask

    // ========================================================================
    // Main Test Sequence
    // ========================================================================
    initial begin
        // Setup waveform dump
        $dumpfile("mlp_tb.vcd");
        $dumpvars(0, tb_FinalProjectP1);

        // Initialize
        rst_n    = 1'b0;
        in_valid = 1'b0;
        x_flat   = {IN_DIM*XW{1'b0}};

        // Reset sequence
        repeat(2) @(posedge clk);
        rst_n = 1'b1;
        @(posedge clk);

        $display("\n========================================");
        $display("MLP Forward Pass Test");
        $display("========================================");

        // ====================================================================
        // Test 1: All Zeros
        // ====================================================================
        // Expected behavior:
        // z1[0] = 0*32 + 10 = 10 -> a1[0] = 10
        // z1[1] = 0*32 + 5  = 5  -> a1[1] = 5
        // z1[2] = 0*32 + (-5) = -5 -> a1[2] = 0 (ReLU kills it!)
        // z1[3] = 0*32 + 0  = 0  -> a1[3] = 0 (ReLU kills it!)
        // So a1 = [10, 5, 0, 0]
        //
        // z2[0] = 2*10 + 1*5 + (-1)*0 + 3*0 + 20 = 20 + 5 + 20 = 45
        // z2[1] = 1*10 + 1*5 + (-1)*0 + 1*0 + 10 = 10 + 5 + 10 = 25
        // z2[2] = (-1)*10 + (-1)*5 + 1*0 + (-1)*0 + (-10) = -10 -5 -10 = -25
        // z2[3] = 3*10 + 3*5 + 3*0 + 3*0 + 5 = 30 + 15 + 5 = 50
        // z2[4] = 1*10 + 1*5 + 1*0 + 1*0 + 0 = 10 + 5 = 15
        for (i = 0; i < IN_DIM; i = i + 1)
            stim[i] = 0;
        set_input_vector(stim);
        send_vector_and_check("Test 1: All Zeros");
        $display("  Expected: out ≈ [45, 25, -25, 50, 15]");

        // ====================================================================
        // Test 2: All Ones
        // ====================================================================
        // z1[0] = 1*32 + 10 = 42 -> a1[0] = 42
        // z1[1] = (-1)*32 + 5 = -27 -> a1[1] = 0 (ReLU!)
        // z1[2] = (2-1)*16 + (-5) = 16 - 5 = 11 -> a1[2] = 11
        // z1[3] = 1*32 + 0 = 32 -> a1[3] = 32
        // So a1 = [42, 0, 11, 32]
        //
        // z2[0] = 2*42 + 1*0 + (-1)*11 + 3*32 + 20 = 84 - 11 + 96 + 20 = 189
        // z2[1] = 1*42 + 1*0 + (-1)*11 + 1*32 + 10 = 42 - 11 + 32 + 10 = 73
        // z2[2] = (-1)*42 + (-1)*0 + 1*11 + (-1)*32 + (-10) = -42 + 11 - 32 - 10 = -73
        // z2[3] = 3*42 + 3*0 + 3*11 + 3*32 + 5 = 126 + 33 + 96 + 5 = 260
        // z2[4] = 1*42 + 1*0 + 1*11 + 1*32 + 0 = 42 + 11 + 32 = 85
        for (i = 0; i < IN_DIM; i = i + 1)
            stim[i] = 1;
        set_input_vector(stim);
        send_vector_and_check("Test 2: All Ones");
        $display("  Expected: out ≈ [189, 73, -73, 260, 85]");

        // ====================================================================
        // Test 3: Ramp (0..31 but 4-bit signed wraps at 8)
        // ====================================================================
        // In 4-bit signed: 0,1,2,3,4,5,6,7,-8,-7,...,-1,0,1,2,...
        // This creates interesting positive/negative patterns
        for (i = 0; i < IN_DIM; i = i + 1)
            stim[i] = i[XW-1:0];  // wrap to 4-bit
        set_input_vector(stim);
        send_vector_and_check("Test 3: Ramp (4-bit wrap)");
        $display("  Expected: varied outputs (some negative hidden neurons)");

        // ====================================================================
        // Test 4: Alternating +3/-3
        // ====================================================================
        for (i = 0; i < IN_DIM; i = i + 1)
            stim[i] = (i % 2 == 0) ? 4'sd3 : -4'sd3;
        set_input_vector(stim);
        send_vector_and_check("Test 4: Alternating +3/-3");
        $display("  Expected: small variations based on weight patterns");

        // ====================================================================
        // Test 5: Large positive values
        // ====================================================================
        for (i = 0; i < IN_DIM; i = i + 1)
            stim[i] = 4'sd7;  // max positive 4-bit signed
        set_input_vector(stim);
        send_vector_and_check("Test 5: All +7 (max)");
        $display("  Expected: large outputs (some negative from neuron 1)");

        // ====================================================================
        // Test 6: Large negative values
        // ====================================================================
        for (i = 0; i < IN_DIM; i = i + 1)
            stim[i] = -4'sd8;  // min negative 4-bit signed
        set_input_vector(stim);
        send_vector_and_check("Test 6: All -8 (min)");
        $display("  Expected: ReLU will kill most hidden neurons");

        // Done
        $display("\n========================================");
        $display("All tests complete!");
        $display("========================================\n");
        
        repeat(2) @(posedge clk);
        $finish;
    end

    // ========================================================================
    // Monitor for debugging
    // ========================================================================
    always @(posedge clk) begin
        if (out_valid) begin
            $display("[TIME %0t] Output ready: out_valid=%b", $time, out_valid);
        end
    end

endmodule