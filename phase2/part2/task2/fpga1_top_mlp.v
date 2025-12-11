// FPGA1: compute z = W·x (no bias, no activation)
// Then send z over GPIO_LINK and show it on local LEDs for debug.
module fpga1_top_mlp (
    input        CLOCK_50,
    input  [3:0] SW,          // we'll use only SW[3:0] as x
    output [9:0] GPIO_LINK,   // send z over this bus
    output [9:0] LEDR         // local debug display
);
    // Treat switches as x[3:0]
    wire [3:0] x = SW[3:0];

    // 10-bit signed intermediate result
    wire signed [9:0] z;

    // Simple matrix-vector multiply with 1 neuron:
    // z = w0*x0 + w1*x1 + w2*x2 + w3*x3
    // Here x_i are 0 or 1, so this is just sum of selected weights.
    mlp_mvm u_mvm (
        .x(x),
        .z(z)
    );

    // Drive link with z (extend or zero-pad to 10 bits)
    assign GPIO_LINK = z[9:0];

    // For debug: show z on local LEDs
    assign LEDR = z[9:0];
endmodule


// Matrix-vector multiply for 1 neuron, 4 inputs.
// x are 1-bit inputs (0 or 1), z is 10-bit signed.
module mlp_mvm (
    input  [3:0] x,           // x[3:0]
    output signed [9:0] z
);
    // Choose some simple signed weights (10-bit) you like:
    // e.g., w = [1, 2, -1, 3]
    localparam signed [9:0] W0 = 10'sd1;
    localparam signed [9:0] W1 = 10'sd2;
    localparam signed [9:0] W2 = -10'sd1;
    localparam signed [9:0] W3 = 10'sd3;

    // Interpret x bits as 0 or 1 (unsigned is fine here)
    wire [3:0] x_u = x;

    // Sum selected weights based on x bits.
    wire signed [9:0] term0 = x_u[0] ? W0 : 10'sd0;
    wire signed [9:0] term1 = x_u[1] ? W1 : 10'sd0;
    wire signed [9:0] term2 = x_u[2] ? W2 : 10'sd0;
    wire signed [9:0] term3 = x_u[3] ? W3 : 10'sd0;

    assign z = term0 + term1 + term2 + term3;
endmodule


