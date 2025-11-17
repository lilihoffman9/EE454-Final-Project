// mlp_clk.sv

module mlp_top #(
    parameter IN_DIM   = 64,
    parameter H_DIM    = 8,
    parameter OUT_DIM  = 10,
    parameter XW       = 8,
    parameter WW       = 8,
    parameter ACCW     = 32
)(
    input  wire                     clk,
    input  wire                     rst_n,     // active-low reset
    input  wire                     in_valid,  // 1-cycle pulse when x_flat is valid
    input  wire [IN_DIM*XW-1:0]     x_flat,
    output reg                      out_valid, // 1 when out_flat has new data
    output reg  [OUT_DIM*ACCW-1:0]  out_flat
);
    integer i, j;

    // registered input
    reg  [IN_DIM*XW-1:0]  x_reg;

    // unpacked input and intermediate arrays
    reg  signed [XW-1:0]      x      [0:IN_DIM-1];
    reg  signed [ACCW-1:0]    z1     [0:H_DIM-1];
    reg  signed [ACCW-1:0]    a1     [0:H_DIM-1];
    reg  signed [ACCW-1:0]    z2     [0:OUT_DIM-1];

    reg  signed [WW-1:0]      W1     [0:IN_DIM-1][0:H_DIM-1];
    reg  signed [ACCW-1:0]    b1     [0:H_DIM-1];
    reg  signed [WW-1:0]      W2     [0:H_DIM-1][0:OUT_DIM-1];
    reg  signed [ACCW-1:0]    b2     [0:OUT_DIM-1];

    reg  signed [ACCW-1:0]    acc;

    // --- your weight/bias initial block stays as-is here ---

    // 1) Sequential block – register input & outputs
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            x_reg     <= {IN_DIM*XW{1'b0}};
            out_flat  <= {OUT_DIM*ACCW{1'b0}};
            out_valid <= 1'b0;
        end else begin
            // latch new input when in_valid is high
            if (in_valid) begin
                x_reg <= x_flat;
            end

            // latch outputs every cycle (or you could gate with in_valid)
            out_valid <= in_valid;   // 1-cycle latency
            for (j = 0; j < OUT_DIM; j = j + 1) begin
                out_flat[j*ACCW +: ACCW] <= z2[j];
            end
        end
    end

    // 2) Combinational – unpack x_reg, compute dense1 -> ReLU -> dense2
    always @* begin
        // unpack registered input
        for (i = 0; i < IN_DIM; i = i + 1) begin
            x[i] = x_reg[i*XW +: XW];
        end

        // first dense layer
        for (j = 0; j < H_DIM; j = j + 1) begin
            acc = b1[j];
            for (i = 0; i < IN_DIM; i = i + 1) begin
                acc = acc + $signed(x[i]) * $signed(W1[i][j]);
            end
            z1[j] = acc;
        end

        // ReLU
        for (j = 0; j < H_DIM; j = j + 1) begin
            if (z1[j] > 0)
                a1[j] = z1[j];
            else
                a1[j] = {ACCW{1'b0}};
        end

        // second dense layer
        for (j = 0; j < OUT_DIM; j = j + 1) begin
            acc = b2[j];
            for (i = 0; i < H_DIM; i = i + 1) begin
                acc = acc + $signed(a1[i]) * $signed(W2[i][j]);
            end
            z2[j] = acc;
        end
    end

endmodule
