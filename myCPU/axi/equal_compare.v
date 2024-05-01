`timescale 1ns / 1ps

module equal_compare(
    input wire [31:0] a, b,         // Input operands a and b
    input wire [5:0] opD,           // Input operation code opD
    input wire [4:0] rtD,           // Input register target rtD
    output reg y                     // Output comparison result y
);

always @(*) begin
    case (opD)
        // Comparison instructions
        `BEQ : y = (a == b);            // Set y to 1 if a equals b, else 0
        `BNE : y = (a != b);            // Set y to 1 if a not equals b, else 0
        `BGTZ : y = ((a[31] == 1'b0) & (a != `ZeroWord)); // Set y to 1 if a greater than zero, else 0
        `BLEZ : y = ((a[31] == 1'b1) | (a == `ZeroWord)); // Set y to 1 if a less than or equal to zero, else 0
        `REGIMM_INST : begin
            case (rtD) 
                // Conditional branch instructions
                `BGEZ, `BGEZAL : y = (a[31] == 1'b0);  // Set y to 1 if a greater than or equal to zero, else 0
                `BLTZ, `BLTZAL : y = (a[31] == 1'b1);  // Set y to 1 if a less than zero, else 0
                default : y = 1'b0; // Default: y is 0
            endcase
        end
        default : y = 1'b0; // Default: y is 0
    endcase
end

endmodule
