`timescale 1ns / 1ps

module flopenr #(parameter WIDTH = 8)(
    input wire clk,     // Clock signal
    input wire rst,     // Reset signal
    input wire en,      // Enable signal
    input wire [WIDTH-1:0] d,  // Data input
    output reg [WIDTH-1:0] q   // Data output
);

always @(posedge clk) begin
    if (rst) begin
        q <= 0;  // Reset: Set q to 0
    end else if (en) begin
        /* Code */  // When enable signal is high, assign the input data d to q
        q <= d;
    end
end

endmodule
