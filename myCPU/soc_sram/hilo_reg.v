module hilo_reg(
    input wire clk,     // Clock signal
    input wire rst,     // Reset signal
    input wire we,      // Write enable
    input wire[63:0] hilo_in, // Input data to be written
    output wire[63:0] hilo_out // Output data read from the register
);

reg [63:0] hilo_reg; // HILO register

always @(negedge clk) begin
    if (rst) begin
        hilo_reg <= 0; // Reset: Set the register to 0
    end else if (we) begin
        hilo_reg <= hilo_in; // Write data into the register when write enable is active
    end
end

assign hilo_out = hilo_reg; // Output the data read from the HILO register

endmodule
