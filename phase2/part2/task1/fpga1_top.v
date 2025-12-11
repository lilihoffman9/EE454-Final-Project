
module fpga1_top (
    input  [9:0] SW,          // slide switches on FPGA1
    output [9:0] GPIO_LINK   // 10-bit link to FPGA2
);
    // Drive the link with the switches
    assign GPIO_LINK = SW;

    // Also show the switches on this board's LEDs
endmodule





