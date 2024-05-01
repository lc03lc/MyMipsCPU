`timescale 1ns / 1ps
`include "defines2.vh"


module maindec(
    input wire[5:0] op,           // Opcode input
    input wire[5:0] funct,        // Function code input
    input wire[4:0] rs,           // Source register input
    input wire[4:0] rt,           // Target register input
    output wire memtoreg,         // Memory to register signal
    output wire memwrite,         // Memory write signal
    output wire branch,           // Branch signal
    output wire alusrc,           // ALU source signal
    output wire[1:0] regdst,      // Register destination signal
    output wire regwrite,         // Register write signal
    output wire jump,             // Jump signal
    output wire hilo_write,       // HILO write signal
    output wire jbral,            // Jump and link register signal
    output wire jr,               // Jump register signal
    output wire cp0_write,        // CP0 write signal
    output reg is_invalid         // Invalid instruction signal
);

reg[11:0] controls; // Control signals

// Assign control signals based on opcode and function code
always @(*) begin
    is_invalid <= 1'b0; // Initialize invalid signal to 0
    case (op)
        `EXE_R_TYPE:
            case (funct)
                // ALU operations
                `EXE_ADD, `EXE_ADDU, `EXE_SUB, `EXE_SUBU, `EXE_SLT, `EXE_SLTU,
                `EXE_AND, `EXE_NOR, `EXE_OR, `EXE_XOR,
                `EXE_SLLV, `EXE_SLL, `EXE_SRAV, `EXE_SRA, `EXE_SRLV, `EXE_SRL,
                `EXE_MFHI, `EXE_MFLO:            controls <= 12'b1_01_000000000;
                // Multiply and divide operations
                `EXE_DIV, `EXE_DIVU, `EXE_MULT, `EXE_MULTU,
                `EXE_MTHI, `EXE_MTLO:            controls <= 12'b0_00_000001000;
                `EXE_JR:                      controls <= 12'b0_00_000000010;
                `EXE_JALR:                    controls <= 12'b1_01_000000110;
                // Trap instructions
                `EXE_BREAK, `EXE_SYSCALL:          controls <= 12'b0_00_000000000;
                default:  begin
                    controls <= 12'b000000000000;
                    is_invalid <= 1'b1; // Set invalid signal for unrecognized instructions
                end
            endcase

        6'b111111: controls <= 12'b1_01_000000000;

        // I-type instructions
        `EXE_ADDI, `EXE_ADDIU, `EXE_SLTI, `EXE_SLTIU,
        `EXE_ANDI, `EXE_LUI, `EXE_ORI, `EXE_XORI:        controls <= 12'b1_00_100000000;
        `EXE_BEQ, `EXE_BNE, `EXE_BGTZ, `EXE_BLEZ:        controls <= 12'b0_00_010000000;
        `EXE_REGIMM_INST:
            case (rt)
                `EXE_BGEZ, `EXE_BLTZ:            controls <= 12'b0_00_010000000;
                `EXE_BGEZAL, `EXE_BLTZAL:        controls <= 12'b1_10_010000100;
                default:  begin
                    controls <= 12'b000000000000;
                    is_invalid <= 1'b1; // Set invalid signal for unrecognized instructions
                end
            endcase
        `EXE_LB, `EXE_LBU, `EXE_LH, `EXE_LHU, `EXE_LW:        controls <= 12'b1_00_100100000;
        `EXE_SB, `EXE_SH, `EXE_SW:                controls <= 12'b0_00_101000000;
        // J-type instructions
        `EXE_J:        controls <= 12'b0_00_000010000;
        `EXE_JAL:    controls <= 12'b1_10_000010100;
        // Special3 instructions
        `EXE_SPECIAL3_INST:
            case(rs)
                `EXE_MTC0: controls <= 12'b0_00_000000001;
                `EXE_MFC0: controls <= 12'b1_00_000000000;
                `EXE_ERET: controls <= 12'b0_00_000000000;
                default:  begin
                    controls <= 12'b000000000000;
                    is_invalid <= 1'b1; // Set invalid signal for unrecognized instructions
                end
            endcase
        default:  begin
                controls <= 12'b000000000000;
                is_invalid <= 1'b1; // Set invalid signal for unrecognized instructions
        end
    endcase
end

// Assign individual control signals from the control word
assign {regwrite, regdst, alusrc, branch, memwrite, memtoreg, jump, hilo_write, jbral, jr, cp0_write} = controls;

endmodule
