`timescale 1ns / 1ps
`include "defines2.vh"

module alu(
    input wire clk, rst,
    input wire [31:0] a, b,
    input wire [4:0] alucontrolE,
    input wire [4:0] sa,
    input wire [63:0] hilo_in,
    input wire [31:0] cp0_rdata,
    input wire is_except,
    output reg [63:0] hilo_out,
    output reg [31:0] result,
    output wire div_ready,
    output reg div_stall,
    output wire overflow
);

    reg double_sign; // Accumulate double sign bit for handling integer overflow
    assign overflow = (alucontrolE == `EXE_ADD_OP || alucontrolE == `EXE_SUB_OP) & (double_sign ^ result[31]);

    // Divisor (div)
    reg div_start;
    reg div_signed;
    reg [31:0] a_save; // Save two operands during division to prevent data forwarding selector signal changes due to M-stage refresh
    reg [31:0] b_save;
    wire [63:0] div_result;

    always @(*) begin
        double_sign = 0;
        hilo_out = 64'b0;
        if (rst | is_except) begin
            div_stall = 1'b0;
            div_start = 1'b0;
        end
        else begin
            case (alucontrolE)
                // Arithmetic operations (14 instructions)
                `EXE_ADD_OP   :  begin
                    // Perform signed addition and accumulate the double sign bit
                    {double_sign,result} = {a[31],a} + {b[31],b};
                end
                `EXE_ADDU_OP  :  begin
                    // Perform unsigned addition
                    result = a + b;
                end
                `EXE_SUB_OP   :  begin
                    // Perform signed subtraction and accumulate the double sign bit
                    {double_sign,result} = {a[31],a} - {b[31],b};
                end
                `EXE_SUBU_OP  :  begin
                    // Perform unsigned subtraction
                    result = a - b;
                end
                `EXE_SLT_OP   :  begin
                    // Set result to 1 if a is less than b, otherwise set it to 0
                    result = $signed(a) < $signed(b) ? 32'b1 : 32'b0;
                end
                `EXE_SLTU_OP  :  begin
                    // Set result to 1 if a is less than b (unsigned), otherwise set it to 0
                    result = a < b ? 32'b1 : 32'b0;
                end
                `EXE_MULT_OP  :  begin
                    // Perform signed multiplication and store the result in hilo_out
                    hilo_out = $signed(a) * $signed(b);
                end
                `EXE_MULTU_OP :  begin
                    // Perform unsigned multiplication and store the result in hilo_out
                    hilo_out = {32'b0, a} * {32'b0, b};
                end
                `EXE_DIV_OP   :  begin
                    // Division control state machine logic for signed division
                    if (~div_ready & ~div_start) begin
                        div_start <= 1'b1;
                        div_signed <= 1'b1;
                        div_stall <= 1'b1;
                        a_save <= a; // Save two operands during division
                        b_save <= b;
                    end
                    else if (div_ready) begin
                        div_start <= 1'b0;
                        div_signed <= 1'b1;
                        div_stall <= 1'b0;
                        hilo_out <= div_result;
                    end
                end
                `EXE_DIVU_OP  :  begin
                    // Division control state machine logic for unsigned division
                    if (~div_ready & ~div_start) begin
                        div_start <= 1'b1;
                        div_signed <= 1'b0;
                        div_stall <= 1'b1;
                        a_save <= a; // Save two operands during division
                        b_save <= b;
                    end
                    else if (div_ready) begin
                        div_start <= 1'b0;
                        div_signed <= 1'b0;
                        div_stall <= 1'b0;
                        hilo_out <= div_result;
                    end
                end
                // Other instructions
                // ... (Add comments for other instructions as needed)
                default        :  result = `EXE_ZeroWord; // Default result is a zero word
            endcase
        end
    end

    wire annul; // Terminate division signal
    assign annul = ((alucontrolE == `EXE_DIV_OP) | (alucontrolE == `EXE_DIVU_OP)) & is_except;

    // Connect to the division unit
    div div(clk, rst, div_signed, a_save, b_save, div_start, annul, div_result, div_ready);
endmodule
