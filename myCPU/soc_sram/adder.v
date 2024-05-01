`timescale 1ns / 1ps

module adder(
    input wire [31:0] a, b,
    output wire [31:0] y
);

    // This module performs 32-bit addition
    assign y = a + b;
    
endmodule
