`timescale 1ns / 1ps
`include "defines2.vh"

module aludec(
    input wire [5:0] funct,
    input wire [5:0] op,
    input wire [4:0] rs,
    input wire [4:0] rt,
    output reg [4:0] alucontrol
);

always @(*) begin
    case (op)
        `EXE_R_TYPE:
            case (funct)
                // Arithmetic operations
                `EXE_ADD:       alucontrol = `EXE_ADD_OP;
                `EXE_ADDU:      alucontrol = `EXE_ADDU_OP;
                `EXE_SUB:       alucontrol = `EXE_SUB_OP;
                `EXE_SUBU:      alucontrol = `EXE_SUBU_OP;
                `EXE_SLT:       alucontrol = `EXE_SLT_OP;
                `EXE_SLTU:      alucontrol = `EXE_SLTU_OP;
                `EXE_DIV:       alucontrol = `EXE_DIV_OP;
                `EXE_DIVU:      alucontrol = `EXE_DIVU_OP;
                `EXE_MULT:      alucontrol = `EXE_MULT_OP;
                `EXE_MULTU:     alucontrol = `EXE_MULTU_OP;
                // Logical operations
                `EXE_AND:       alucontrol = `EXE_AND_OP;
                `EXE_NOR:       alucontrol = `EXE_NOR_OP;
                `EXE_OR:        alucontrol = `EXE_OR_OP;
                `EXE_XOR:       alucontrol = `EXE_XOR_OP;
                // Shift operations
                `EXE_SLLV:      alucontrol = `EXE_SLLV_OP;
                `EXE_SLL:       alucontrol = `EXE_SLL_OP;
                `EXE_SRAV:      alucontrol = `EXE_SRAV_OP;
                `EXE_SRA:       alucontrol = `EXE_SRA_OP;
                `EXE_SRLV:      alucontrol = `EXE_SRLV_OP;
                `EXE_SRL:       alucontrol = `EXE_SRL_OP;
                // Data movement
                `EXE_MFHI:      alucontrol = `EXE_MFHI_OP;
                `EXE_MTHI:      alucontrol = `EXE_MTHI_OP;
                `EXE_MFLO:      alucontrol = `EXE_MFLO_OP;
                `EXE_MTLO:      alucontrol = `EXE_MTLO_OP;
                // JALR
                `EXE_JALR:      alucontrol = `EXE_ADDU_OP; // Perform addition for JALR
                default:    alucontrol = `EXE_USELESS_OP;
            endcase
        6'b111111: alucontrol = 5'b10110; // Special case for MUL and DIV instructions

        // I-type instructions
        // Arithmetic operations
        `EXE_ADDI:      alucontrol = `EXE_ADD_OP;
        `EXE_ADDIU:     alucontrol = `EXE_ADDU_OP;
        `EXE_SLTI:      alucontrol = `EXE_SLT_OP;
        `EXE_SLTIU:     alucontrol = `EXE_SLTU_OP;
        // Logical operations
        `EXE_ANDI:      alucontrol = `EXE_AND_OP;
        `EXE_LUI:       alucontrol = `EXE_LUI_OP;
        `EXE_ORI:       alucontrol = `EXE_OR_OP;
        `EXE_XORI:      alucontrol = `EXE_XOR_OP;
        // Memory access
        `EXE_LB, `EXE_LBU, `EXE_LH, `EXE_LHU, `EXE_LW, `EXE_SB, `EXE_SH, `EXE_SW: alucontrol = `EXE_ADDU_OP; // Default to addition for memory operations
        // Conditional branch instructions
        `EXE_REGIMM_INST:
            case(rt)
                `EXE_BGEZAL, `EXE_BLTZAL: alucontrol = `EXE_ADDU_OP; // Perform addition for conditional branch instructions
                default:    alucontrol = `EXE_USELESS_OP;
            endcase
        `EXE_JAL : alucontrol = `EXE_ADDU_OP; // Perform addition for JAL instruction
        // Special instructions for exceptions
        `EXE_SPECIAL3_INST:
            case(rs)
                `EXE_MTC0:   alucontrol = `EXE_MTC0_OP; // Move from Coprocessor 0
                `EXE_MFC0:   alucontrol = `EXE_MFC0_OP; // Move to Coprocessor 0
                default:    alucontrol = `EXE_USELESS_OP;
            endcase  
        default:    alucontrol = `EXE_USELESS_OP;
    endcase
end

endmodule
