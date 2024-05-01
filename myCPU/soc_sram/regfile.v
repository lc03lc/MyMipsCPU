`timescale 1ns / 1ps

module regfile(
    input wire clk,
    input wire we3,
    input wire[4:0] ra1, ra2, wa3,
    input wire[31:0] wd3,
    output wire[31:0] rd1, rd2
);

    reg [31:0] rf[31:0]; // Register file with 32 32-bit registers.

    always @(negedge clk) begin
        if (we3) begin
            rf[wa3] <= wd3; // Write data to the selected register when we3 is active.
        end
    end

    assign rd1 = (ra1 != 0) ? rf[ra1] : 0; // Read data from ra1 or set to 0 if ra1 is 0.
    assign rd2 = (ra2 != 0) ? rf[ra2] : 0; // Read data from ra2 or set to 0 if ra2 is 0.
endmodule
