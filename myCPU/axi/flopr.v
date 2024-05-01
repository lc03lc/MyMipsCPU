`timescale 1ns / 1ps

// Flip-flop with clock (clk) and reset (rst) signals
module flopr #(parameter WIDTH = 8)(
    input wire clk,     // Clock signal
    input wire rst,     // Reset signal
    input wire [WIDTH-1:0] d,  // Data input
    output reg [WIDTH-1:0] q   // Data output
);

always @(posedge clk, posedge rst) begin
    if (rst) begin
        q <= 0;  // Reset: Set q to 0
    end else begin
        q <= d;  // When there's no reset, assign the input data d to q on the rising edge of clk
    end
end

endmodule
