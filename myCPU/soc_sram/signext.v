`timescale 1ns / 1ps

module signext(
    input wire[15:0] a,        // Input 16-bit data.
    input wire[1:0] inst_type, // Input 2-bit instruction type.
    output wire[31:0] y        // Output 32-bit sign-extended data.
);

    assign y = (inst_type == 2'b11) ? {{16{1'b0}}, a} : {{16{a[15]}}, a};
    // If inst_type is "11" (b11), sign-extend by adding 16 zero bits to the left.
    // Otherwise, sign-extend by repeating the most significant bit of 'a' to the left.
endmodule
