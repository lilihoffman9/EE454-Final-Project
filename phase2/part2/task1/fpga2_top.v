module fpga2_top (
    input  [9:0] GPIO_LINK,
    output [9:0] LEDR
);
    // All 10 LEDs follow the 10-bit link
    assign LEDR = GPIO_LINK;
endmodule
