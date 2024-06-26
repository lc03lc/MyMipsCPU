`timescale 1ns / 1ps

module pc #(parameter WIDTH = 8)(
    input wire clk, rst, en,
    input wire[WIDTH-1:0] d,
    output reg[WIDTH-1:0] q
);

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            q <= 32'hbfc00000; // Initialize q with a specific value on reset
        end else if (en) begin
            q <= d; // Update q with the input value when enabled
        end
    end
endmodule
