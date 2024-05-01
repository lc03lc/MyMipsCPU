`timescale 1ns / 1ps
`include "defines2.vh"

module except_detection(
    input wire clk,                // Clock signal
    input wire rst,                // Reset signal
    input wire [5:0] ext_int,      // External interrupts from the CPU hardware
    input wire [31:0] cp0_status,  // Value of CP0's Status register for interrupt checking
    input wire [31:0] cp0_cause,   // Value of CP0's Cause register for software interrupts
    input wire [31:0] cp0_epc,     // Value of CP0's Epc register
    input wire is_syscallM,        // SYSCALL instruction flag
    input wire is_breakM,          // BREAK instruction flag
    input wire is_eretM,           // ERET instruction flag
    input wire is_AdEL_pcM,        // Misaligned PC fetch flag
    input wire is_AdEL_dataM,      // Misaligned Load address flag
    input wire is_AdESM,           // Misaligned Store address flag
    input wire is_overflowM,       // Integer overflow flag
    input wire is_invalidM,        // Invalid/Reserved instruction flag

    output reg is_except,          // Exception trigger flag
    output reg [31:0] except_type, // Exception type
    output reg [31:0] except_pc    // Next PC when an exception is triggered (Unified entry address for all exceptions: 32'hBFC00380)
);

always @(*) begin
    if (rst) begin
        is_except <= 1'b0;
        except_type <= 32'b0;
        except_pc <= 32'b0;
    end else begin
        if ((cp0_status[15:8] & {ext_int,cp0_cause[9:8]}) != 8'h00 &
            (cp0_status[1] == 1'b0) & cp0_status[0] == 1'b1) begin
            // Software or hardware interrupt
            is_except <= 1'b1;
            except_type <= 32'h00000001;
            except_pc <= 32'hBFC00380;
        end else if (is_AdEL_pcM | is_AdEL_dataM) begin
            // Misaligned PC fetch or Load misalignment
            is_except <= 1'b1;
            except_type <= 32'h00000004;
            except_pc <= 32'hBFC00380;
        end else if (is_AdESM) begin
            // Store misalignment
            is_except <= 1'b1;
            except_type <= 32'h00000005;
            except_pc <= 32'hBFC00380;
        end else if (is_syscallM) begin
            // SYSCALL
            is_except <= 1'b1;
            except_type <= 32'h00000008;
            except_pc <= 32'hBFC00380;
        end else if (is_breakM) begin
            // BREAK
            is_except <= 1'b1;
            except_type <= 32'h00000009;
            except_pc <= 32'hBFC00380;
        end else if (is_invalidM) begin
            // Invalid/Reserved instruction
            is_except <= 1'b1;
            except_type <= 32'h0000000a;
            except_pc <= 32'hBFC00380;
        end else if (is_overflowM) begin
            // Integer overflow
            is_except <= 1'b1;
            except_type <= 32'h0000000c;
            except_pc <= 32'hBFC00380;
        end else if (is_eretM) begin
            // ERET
            is_except <= 1'b1;
            except_type <= 32'h0000000e;
            except_pc <= cp0_epc;    // Return address
        end else begin
            is_except <= 1'b0;
            except_type <= 32'b0;
            except_pc <= 32'b0;
        end
    end
end

endmodule
