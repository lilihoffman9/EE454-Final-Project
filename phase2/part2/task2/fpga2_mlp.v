// =====================
// Top-level for FPGA2
// =====================
module fpga2_mlp (
    input        CLOCK_50,
    input  [9:0] GPIO_LINK,   // incoming z
    output [9:0] LEDR         // show y
);
    // Treat incoming bus as signed z
    wire signed [9:0] z = GPIO_LINK;

    wire signed [9:0] y;

    mlp_bias_relu u_bias_relu (
        .z(z),
        .y(y)
    );

    // Display activated output on LEDs
    assign LEDR = y[9:0];
endmodule

// =====================
// Bias + ReLU module
// =====================
module mlp_bias_relu (
    input  signed [9:0] z,
    output signed [9:0] y
);
    // Example bias: -1 (you can change this)
    localparam signed [9:0] BIAS = -10'sd1;

    wire signed [9:0] sum = z + BIAS;

    // ReLU: if sum < 0, output 0; else sum
    assign y = (sum[9] == 1'b1) ? 10'sd0 : sum;
endmodule

