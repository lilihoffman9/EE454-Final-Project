// FinalProjectP1.sv
// 2-Layer MLP: Input(32x4bit) -> Hidden(4) -> Output(5)
// Pipeline: 1 cycle latency (input register -> compute -> output register)

module FinalProjectP1 #(
    parameter IN_DIM   = 32,
    parameter H_DIM    = 4,
    parameter OUT_DIM  = 5,
    parameter XW       = 4,
    parameter WW       = 8,
    parameter ACCW     = 16
)(
    input  wire                     clk,
    input  wire                     rst_n,
    input  wire                     in_valid,
    input  wire [IN_DIM*XW-1:0]     x_flat,
    output reg                      out_valid,
    output reg  [OUT_DIM*ACCW-1:0]  out_flat
);

    integer i, j;

    // =========================================================================
    // Pipeline Registers
    // =========================================================================
    reg  [IN_DIM*XW-1:0]  x_reg;        // Stage 0: input register
    reg                   valid_reg;    // Stage 1: validity tracking
    
    // =========================================================================
    // Unpacked arrays for computation
    // =========================================================================
    reg  signed [XW-1:0]      x      [0:IN_DIM-1];   // unpacked input
    reg  signed [ACCW-1:0]    z1     [0:H_DIM-1];    // layer1 pre-activation
    reg  signed [ACCW-1:0]    a1     [0:H_DIM-1];    // layer1 post-ReLU
    reg  signed [ACCW-1:0]    z2     [0:OUT_DIM-1];  // layer2 output

    // =========================================================================
    // Weights and Biases (initialized to create interesting behavior)
    // =========================================================================
    reg  signed [WW-1:0]      W1     [0:IN_DIM-1][0:H_DIM-1];
    reg  signed [ACCW-1:0]    b1     [0:H_DIM-1];
    reg  signed [WW-1:0]      W2     [0:H_DIM-1][0:OUT_DIM-1];
    reg  signed [ACCW-1:0]    b2     [0:OUT_DIM-1];

    reg  signed [ACCW-1:0]    acc;

    // =========================================================================
    // Weight Initialization: VARIED weights to show ReLU effects
    // =========================================================================
    (* ramstyle = "logic" *) 
    (* keep = "true" *)
    initial begin : INIT_WEIGHTS
        integer i, j;

        // W1: Different patterns for each hidden neuron
        // Neuron 0: positive weights -> likely positive z1[0]
        for (i = 0; i < IN_DIM; i = i + 1)
            W1[i][0] = 8'sd1;
        
        // Neuron 1: negative weights -> likely negative z1[1] (ReLU kills it)
        for (i = 0; i < IN_DIM; i = i + 1)
            W1[i][1] = -8'sd1;
        
        // Neuron 2: mixed weights (alternating +/-)
        for (i = 0; i < IN_DIM; i = i + 1)
            W1[i][2] = (i % 2 == 0) ? 8'sd2 : -8'sd1;
        
        // Neuron 3: small positive weights
        for (i = 0; i < IN_DIM; i = i + 1)
            W1[i][3] = 8'sd1;

        // b1: Varied biases
        b1[0] =  10;   // positive bias
        b1[1] =  5;    // small positive (may not overcome negative weights)
        b1[2] = -5;    // negative bias
        b1[3] =  0;    // zero bias

        // W2: Different weights for each output
        for (i = 0; i < H_DIM; i = i + 1) begin
            W2[i][0] =  2;   // output 0: amplify
            W2[i][1] =  1;   // output 1: pass through
            W2[i][2] = -1;   // output 2: invert
            W2[i][3] =  3;   // output 3: amplify more
            W2[i][4] =  1;   // output 4: pass through
        end

        // b2: Varied biases for outputs
        b2[0] =  20;
        b2[1] =  10;
        b2[2] = -10;
        b2[3] =  5;
        b2[4] =  0;
    end

    // =========================================================================
    // Sequential Logic: Pipeline Registers
    // =========================================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            x_reg     <= {IN_DIM*XW{1'b0}};
            valid_reg <= 1'b0;
            out_valid <= 1'b0;
            out_flat  <= {OUT_DIM*ACCW{1'b0}};
        end else begin
            // Stage 0->1: Capture input when valid
            if (in_valid)
                x_reg <= x_flat;
            
            // Stage 1->2: Delay valid signal by 1 cycle
            valid_reg <= in_valid;
            
            // Stage 2: Output when computation is done
            out_valid <= valid_reg;
            
            if (valid_reg) begin
                for (j = 0; j < OUT_DIM; j = j + 1)
                    out_flat[j*ACCW +: ACCW] <= z2[j];
            end
        end
    end

    // =========================================================================
    // Combinational Logic: MLP Forward Pass
    // =========================================================================
    always @* begin
        // Unpack input vector
        for (i = 0; i < IN_DIM; i = i + 1)
            x[i] = x_reg[i*XW +: XW];

        // Layer 1: z1 = W1 * x + b1
        for (j = 0; j < H_DIM; j = j + 1) begin
            acc = b1[j];
            for (i = 0; i < IN_DIM; i = i + 1)
                acc = acc + $signed(x[i]) * $signed(W1[i][j]);
            z1[j] = acc;
        end

        // ReLU activation: a1 = max(0, z1)
        for (j = 0; j < H_DIM; j = j + 1)
            a1[j] = (z1[j] > 0) ? z1[j] : {ACCW{1'b0}};

        // Layer 2: z2 = W2 * a1 + b2
        for (j = 0; j < OUT_DIM; j = j + 1) begin
            acc = b2[j];
            for (i = 0; i < H_DIM; i = i + 1)
                acc = acc + $signed(a1[i]) * $signed(W2[i][j]);
            z2[j] = acc;
        end
    end

endmodule