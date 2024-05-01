`timescale 1ns / 1ps

module mux2 #(parameter WIDTH = 8)(
    input wire[WIDTH-1:0] d0, d1,
    input wire s,
    output wire[WIDTH-1:0] y
);

    assign y = s ? d1 : d0;
endmodule

module mycpu_top(
    input clk,
    input resetn,  // Active low
    input [5:0] ext_int,
    // CPU instruction SRAM
    output inst_sram_en,
    output [3:0] inst_sram_wen,
    output [31:0] inst_sram_addr,
    output [31:0] inst_sram_wdata,
    input [31:0] inst_sram_rdata,
    // CPU data SRAM
    output data_sram_en,
    output [3:0] data_sram_wen,
    output [31:0] data_sram_addr,
    output [31:0] data_sram_wdata,
    input [31:0] data_sram_rdata,
    // For debugging
    output [31:0] debug_wb_pc,
    output [3:0] debug_wb_rf_wen,
    output [4:0] debug_wb_rf_wnum,
    output [31:0] debug_wb_rf_wdata
);

    wire [31:0] pc;
    wire [31:0] instr;
    wire data_en;
    wire memwrite;
    wire [31:0] aluout, writedata, readdata;
    wire [3:0] mem_wen;

    // For MMU
    wire [31:0] inst_vaddr;
    wire [31:0] inst_paddr;
    wire [31:0] data_vaddr;
    wire [31:0] data_paddr;

    mips mips(
        .clk(~clk),  // Inverted clock for synchronous RAM access
        .rst(~resetn),
        .ext_int(ext_int),
        // Instruction
        // .inst_en(inst_en),
        .pcF(pc),                    // pcF
        .instrF(instr),              // instrF
        // Data
        .mem_enM(data_en),
        .memwriteM(memwrite),
        .aluoutM(aluout),
        .mem_write_dataM(writedata),
        .readdataM(readdata),
        .mem_wenM(mem_wen),
        // For debugging
        .debug_wb_pc(debug_wb_pc),
        .debug_wb_rf_wen(debug_wb_rf_wen),
        .debug_wb_rf_wnum(debug_wb_rf_wnum),
        .debug_wb_rf_wdata(debug_wb_rf_wdata)
    );

    assign inst_vaddr = pc;
    assign data_vaddr = aluout;
    mmu mmu(
        .inst_vaddr(inst_vaddr),
        .inst_paddr(inst_paddr),
        .data_vaddr(data_vaddr),
        .data_paddr(data_paddr)
    );

    assign inst_sram_en = 1'b1;     // If inst_en is available, use it
    assign inst_sram_wen = 4'b0;
    assign inst_sram_addr = inst_paddr;
    assign inst_sram_wdata = 32'b0;
    assign instr = inst_sram_rdata;

    assign data_sram_en = data_en;     // If data_en is available, use it
    assign data_sram_wen = mem_wen;
    assign data_sram_addr = data_paddr;
    assign data_sram_wdata = writedata;
    assign readdata = data_sram_rdata;

    // ASCII
    instdec instdec(
        .instr(instr)
    );

endmodule
