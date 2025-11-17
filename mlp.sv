// ============================================================================
// mlp.v
// Simple MLP forward pass in Verilog
// Architecture: 64 (input) -> 8 (hidden, ReLU) -> 10 (output logits)
// Integer, quantized style (int8 weights, int32 accumulators).
//
// You should fill in W1_q, b1_q, W2_q, b2_q using the values
// printed by the provided Python reference (W1_q, b1_q, W2_q, b2_q).
// ============================================================================

`timescale 1ns/1ps

module mlp_top #(
    parameter IN_DIM   = 64,
    parameter H_DIM    = 8,
    parameter OUT_DIM  = 10,
    parameter XW       = 8,   // input bit width (int8)
    parameter WW       = 8,   // weight bit width (int8)
    parameter ACCW     = 32   // accumulator/output width (int32)
)(
    // Input feature vector: 64 int8 values, flattened
    input  wire [IN_DIM*XW-1:0]      x_flat,

    // Output logits: 10 int32 values, flattened
    output reg  [OUT_DIM*ACCW-1:0]   out_flat
);

    // ------------------------------------------------------------------------
    // Internal unpacked arrays
    // ------------------------------------------------------------------------
    integer i, j;

    // Input vector as signed int8
    reg signed [XW-1:0]  x      [0:IN_DIM-1];

    // Hidden layer pre-activation and post-ReLU (int32)
    reg signed [ACCW-1:0] z1    [0:H_DIM-1];
    reg signed [ACCW-1:0] a1    [0:H_DIM-1];

    // Output layer logits (int32)
    reg signed [ACCW-1:0] z2    [0:OUT_DIM-1];

    // Weights and biases: int8 weights, int32 biases
    reg signed [WW-1:0]   W1    [0:IN_DIM-1][0:H_DIM-1];
    reg signed [ACCW-1:0] b1    [0:H_DIM-1];

    reg signed [WW-1:0]   W2    [0:H_DIM-1][0:OUT_DIM-1];
    reg signed [ACCW-1:0] b2    [0:OUT_DIM-1];

    // temp accumulator
    reg signed [ACCW-1:0] acc;

    // ------------------------------------------------------------------------
    // Initialize weights/biases.
    //
    // *** IMPORTANT ***
    // Replace the simple demo initialization below with the int8 values
    // printed by your Python script (W1_q, b1_q, W2_q, b2_q).
    //
    // For example, for W1_q (shape [64, 8]) you’d do:
    //
    //   initial begin
    //     W1[0][0] = 8'sd...; W1[1][0] = 8'sd...; ...
    //     b1[0] = 32'sd...;
    //     ...
    //   end
    //
    // For now, we just fill them with small constant values so the
    // structure simulates even before you plug in real parameters.
    // ------------------------------------------------------------------------
    integer r, c;
    initial begin
        // simple deterministic demo weights:
        for (c = 0; c < H_DIM; c = c + 1) begin
            b1[c] = 0;
            for (r = 0; r < IN_DIM; r = r + 1) begin
                // e.g. all ones
                W1[r][c] = 8'sd1;
            end
        end

        for (c = 0; c < OUT_DIM; c = c + 1) begin
            b2[c] = 0;
            for (r = 0; r < H_DIM; r = r + 1) begin
                // e.g. all ones
                W2[r][c] = 8'sd1;
            end
        end
    end

    // ------------------------------------------------------------------------
    // Unpack input bus x_flat -> x[0..IN_DIM-1]
    // x_flat layout: x[0] in bits [7:0], x[1] in [15:8], ...
    // ------------------------------------------------------------------------
    always @* begin
        for (i = 0; i < IN_DIM; i = i + 1) begin
            x[i] = x_flat[i*XW +: XW];
        end
    end

    // ------------------------------------------------------------------------
    // Forward pass: dense1 + ReLU + dense2
    // Fully combinational.
    // ------------------------------------------------------------------------
    always @* begin
        // First dense layer: z1[j] = b1[j] + sum_i x[i] * W1[i][j]
        for (j = 0; j < H_DIM; j = j + 1) begin
            acc = b1[j];
            for (i = 0; i < IN_DIM; i = i + 1) begin
                acc = acc + $signed(x[i]) * $signed(W1[i][j]);
            end
            z1[j] = acc;
        end

        // ReLU: a1[j] = max(0, z1[j])
        for (j = 0; j < H_DIM; j = j + 1) begin
            if (z1[j] > 0)
                a1[j] = z1[j];
            else
                a1[j] = {ACCW{1'b0}};
        end

        // Second dense layer: z2[k] = b2[k] + sum_j a1[j] * W2[j][k]
        for (j = 0; j < OUT_DIM; j = j + 1) begin
            acc = b2[j];
            for (i = 0; i < H_DIM; i = i + 1) begin
                acc = acc + $signed(a1[i]) * $signed(W2[i][j]);
            end
            z2[j] = acc;
        end

        // Pack outputs: z2[0] -> out_flat[31:0], z2[1] -> [63:32], etc.
        for (j = 0; j < OUT_DIM; j = j + 1) begin
            out_flat[j*ACCW +: ACCW] = z2[j];
        end
    end

endmodule
