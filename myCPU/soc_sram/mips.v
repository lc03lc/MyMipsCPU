`timescale 1ns / 1ps

module mips(
    input wire clk, rst,
    input wire [5:0] ext_int, // Hardware interrupt flags
    output wire[31:0] pcF, // Program Counter for Fetch stage
    input wire[31:0] instrF, // Instruction fetched from memory
    output wire memwriteM, // Memory write signal for Mem stage
    output wire[31:0] aluoutM, mem_write_dataM, // ALU output and Memory write data for Mem stage
    input wire[31:0] readdataM, // Data read from memory
    output wire mem_enM, // Memory enable signal for Mem stage
    output wire [3:0] mem_wenM, // Memory write enable signal for Mem stage
    // for debug
    output [31:0] debug_wb_pc,
    output [3:0] debug_wb_rf_wen,
    output [4:0] debug_wb_rf_wnum,
    output [31:0] debug_wb_rf_wdata
);

    // Fetch stage datapath
    wire stallF;
    wire is_AdEL_pcF;
    wire is_in_delayslotF; // Whether the current instruction is in a delay slot

    // PC
    wire [31:0] pcnextFD, pcnextbrFD, pcplus4F, pcbranchD, pcnextjrD, pcnextF;

    // Decode stage controller
    wire pcsrcD;
    wire equalD;
    wire regwriteD, alusrcD, branchD, memwriteD, memtoregD, jumpD;
    wire[1:0] regdstD;
    wire[4:0] alucontrolD;
    wire hilo_writeD; // Obtained from maindec decoding
    wire is_invalidD; // Indicates an invalid instruction
    wire jbralD, jrD, cp0_writeD;
    // Decode stage datapath
    wire [31:0] pcplus4D, instrD;
    wire forwardaD, forwardbD;
    wire [5:0] opD, functD;
    wire [4:0] rsD, rtD, rdD, saD;
    wire stallD, flushD;
    wire [31:0] signimmD, signimmshD;
    wire [31:0] srcaD, srca2D, srcbD, srcb2D;
    wire is_AdEL_pcD, is_syscallD, is_breakD, is_eretD; // Exception flags
    wire is_in_delayslotD;
    wire [31:0] pcD;
    wire [4:0] cp0_waddrD; // CP0 write address for MTC0
    wire [4:0] cp0_raddrD; // CP0 read address for MFC0

    // Execute stage controller
    wire regwriteE, alusrcE, memwriteE, memtoregE;
    wire[1:0] regdstE;
    wire[4:0] alucontrolE;
    wire hilo_writeE; // HILO register write signal
    wire is_invalidE;
    wire jbralE, cp0_writeE;
    // Execute stage datapath
    wire [1:0] forwardaE, forwardbE;
    wire [5:0] opE;
    wire [4:0] rsE, rtE, rdE, saE;
    wire [4:0] writeregE;
    wire [31:0] signimmE;
    wire [31:0] srcaE, srca2E, srca3E, srcbE, srcb2E, srcb3E, srcb4E;
    wire [31:0] aluoutE;
    wire [63:0] read_hiloE, write_hiloE; // HILO read and write data
    wire hilo_write2E; // Adjusted HILO register write signal for division
    wire div_readyE; // Division operation completion signal
    wire div_stallE; // Pipeline stall due to division
    wire stallE, flushE; // Execution stage stall and flush signals
    wire is_AdEL_pcE, is_syscallE, is_breakE, is_eretE, is_overflowE; // Exception flags
    wire is_in_delayslotE;
    wire [31:0] pcE;
    wire [4:0] cp0_waddrE;
    wire [4:0] cp0_raddrE;
    wire [31:0] cp0_rdataE, cp0_rdata2E;

    // Memory stage controller
    wire regwriteM, memtoregM;
    wire is_invalidM; // Reserved instruction flag
    wire cp0_writeM; // CP0 register write signal
    // Memory stage datapath
    wire [5:0] opM;
    wire [4:0] writeregM;
    wire [31:0] final_read_dataM, writedataM;
    wire flushM;
    wire is_AdEL_pcM, is_syscallM, is_breakM, is_eretM, is_AdEL_dataM, is_AdESM, is_overflowM; // Exception flags
    wire is_in_delayslotM;
    wire [31:0] pcM;
    wire [4:0] cp0_waddrM;
    wire is_exceptM;
    wire [31:0] except_typeM;
    wire [31:0] except_pcM;
    wire [31:0] cp0_countM, cp0_compareM, cp0_statusM, cp0_causeM,
        cp0_epcM, cp0_configM, cp0_pridM, cp0_badvaddrM;
    wire cp0_timer_intM;
    wire [31:0] bad_addrM;

    // Writeback stage controller
    wire regwriteW, memtoregW;
    // Writeback stage datapath
    wire [4:0] writeregW;
    wire [31:0] aluoutW, readdataW, resultW;
    wire flushW;

    wire [31:0] pcW;
    wire [31:0] instrE, instrM, instrW;
    flopr #(32) rinstrE(clk, rst, instrD, instrE);
    flopr #(32) rinstrM(clk, rst, instrE, instrM);
    flopr #(32) rinstrW(clk, rst, instrM, instrW);

    flopr #(32) rpcW(clk, rst, pcM, pcW);
    assign debug_wb_pc = pcW;
    assign debug_wb_rf_wen = {4{regwriteW}};
    assign debug_wb_rf_wnum = writeregW;
    assign debug_wb_rf_wdata = resultW;

    maindec md(
        opD,
        functD,
        rsD,
        rtD,
        memtoregD, memwriteD,
        branchD, alusrcD,
        regdstD, regwriteD,
        jumpD,
        hilo_writeD,
        jbralD,
        jrD,
        cp0_writeD,
        is_invalidD
    );
    aludec ad(functD, opD, rsD, rtD, alucontrolD);

    assign pcsrcD = branchD & equalD;

    // Pipeline registers
    flopenrc #(15) regE(
        clk,
        rst,
        ~stallE,
        flushE,
        {memtoregD, memwriteD, alusrcD, regdstD, regwriteD, alucontrolD, hilo_writeD, jbralD, cp0_writeD, is_invalidD},
        {memtoregE, memwriteE, alusrcE, regdstE, regwriteE, alucontrolE, hilo_writeE, jbralE, cp0_writeE, is_invalidE}
    );
    floprc #(5) regM(
        clk, rst, flushM,
        {memtoregE, memwriteE, regwriteE, cp0_writeE, is_invalidE},
        {memtoregM, memwriteM, regwriteM, cp0_writeM, is_invalidM}
    );
    floprc #(2) regW(
        clk, rst, flushW,
        {memtoregM, regwriteM},
        {memtoregW, regwriteW}
    );

	// Hazard detection
hazard h(
    // Fetch stage
    stallF,                  // Stall flag in fetch stage
    // Decode stage
    rsD, rtD,               // Source registers for the instruction in decode stage
    branchD,                // Branch instruction in decode stage
    jrD,                    // Jump register instruction in decode stage
    forwardaD, forwardbD,   // Forwarding signals in decode stage
    stallD,                 // Stall flag in decode stage
    // Execute stage
    rsE, rtE,               // Source registers for the instruction in execute stage
    writeregE,              // Register to write the result to in execute stage
    regwriteE,              // Flag indicating if a register write occurs in execute stage
    memtoregE,              // Flag indicating if memory-to-register write occurs in execute stage
    div_stallE,             // Stall flag for divide unit in execute stage
    forwardaE, forwardbE,   // Forwarding signals in execute stage
    flushD, flushE, flushM, flushW,   // Flush signals for pipeline stages
    stallE,                 // Stall flag in execute stage
    // Memory stage
    writeregM,              // Register to write the result to in memory stage
    regwriteM,              // Flag indicating if a register write occurs in memory stage
    memtoregM,              // Flag indicating if memory-to-register write occurs in memory stage
    is_exceptM,             // Exception flag in memory stage
    // Write back stage
    writeregW,              // Register to write the result to in write back stage
    regwriteW               // Flag indicating if a register write occurs in write back stage
);

// Next PC logic (operates in fetch and decode)
mux2 #(32) pcbrmux(pcplus4F, pcbranchD, pcsrcD, pcnextbrFD);
mux2 #(32) pcjumpmux(pcnextbrFD,
    {pcplus4D[31:28], instrD[25:0], 2'b00},
    jumpD, pcnextFD);
mux2 #(32) pc_jr_mux(pcnextFD, srca2D, jrD, pcnextjrD);
mux2 #(32) pc_except_mux(pcnextjrD, except_pcM, is_exceptM, pcnextF); // Exception handling

// Register file (operates in decode and writeback)
regfile rf(clk, regwriteW, rsD, rtD, writeregW, resultW, srcaD, srcbD);

// Fetch stage logic
pc #(32) pcreg(clk, rst, ~stallF, pcnextF, pcF);
adder pcadd1(pcF, 32'b100, pcplus4F);

assign is_AdEL_pcF = ~(pcF[1:0] == 2'b00);
assign is_in_delayslotF = jumpD | branchD | jbralD | jrD;

// Decode stage
flopenrc #(32) r1D(clk, rst, ~stallD, flushD, pcplus4F, pcplus4D);
flopenrc #(32) r2D(clk, rst, ~stallD, flushD, instrF, instrD);
flopenrc #(1) r3D(clk, rst, ~stallD, flushD, is_AdEL_pcF, is_AdEL_pcD);
flopenrc #(1) r4D(clk, rst, ~stallD, flushD, is_in_delayslotF, is_in_delayslotD);
flopenrc #(32) r5D(clk, rst, ~stallD, flushD, pcF, pcD);

signext se(instrD[15:0], opD[3:2], signimmD);
sl2 immsh(signimmD, signimmshD);
adder pcadd2(pcplus4D, signimmshD, pcbranchD);
mux2 #(32) forwardamux(srcaD, aluoutM, forwardaD, srca2D);
mux2 #(32) forwardbmux(srcbD, aluoutM, forwardbD, srcb2D);
equal_compare comp(srca2D, srcb2D, opD, rtD, equalD);

assign opD = instrD[31:26];
assign functD = instrD[5:0];
assign rsD = instrD[25:21];
assign rtD = instrD[20:16];
assign rdD = instrD[15:11];
assign saD = instrD[10:6];

assign is_breakD = (opD == 6'b000000) & (functD == `BREAK);
assign is_syscallD = (opD == 6'b000000) & (functD == `SYSCALL);
assign is_eretD = (instrD == 32'b01000010000000000000000000011000);
assign cp0_waddrD = rdD;
assign cp0_raddrD = rdD;

// Execute stage
flopenrc #(32) r1E(clk, rst, ~stallE, flushE, srcaD, srcaE);
flopenrc #(32) r2E(clk, rst, ~stallE, flushE, srcbD, srcbE);
flopenrc #(32) r3E(clk, rst, ~stallE, flushE, signimmD, signimmE);
flopenrc #(5) r4E(clk, rst, ~stallE, flushE, rsD, rsE);
flopenrc #(5) r5E(clk, rst, ~stallE, flushE, rtD, rtE);
flopenrc #(5) r6E(clk, rst, ~stallE, flushE, rdD, rdE);
flopenrc #(5) r7E(clk, rst, ~stallE, flushE, saD, saE);
flopenrc #(6) r8E(clk, rst, ~stallE, flushE, opD, opE);
flopenrc #(4) r9E(clk, rst, ~stallE, flushE,
    {is_AdEL_pcD, is_syscallD, is_breakD, is_eretD},
    {is_AdEL_pcE, is_syscallE, is_breakE, is_eretE});
flopenrc #(1) r10E(clk, rst, ~stallE, flushE, is_in_delayslotD, is_in_delayslotE);
flopenrc #(32) r11E(clk, rst, ~stallE, flushE, pcD, pcE);
flopenrc #(5) r12E(clk, rst, ~stallE, flushE, cp0_waddrD, cp0_waddrE);
flopenrc #(5) r13E(clk, rst, ~stallE, flushE, cp0_raddrD, cp0_raddrE);

mux3 #(32) forwardaemux(srcaE, resultW, aluoutM, forwardaE, srca2E);
mux3 #(32) forwardbemux(srcbE, resultW, aluoutM, forwardbE, srcb2E);
mux2 #(32) srcbmux(srcb2E, signimmE, alusrcE, srcb3E);
// Jump and link instructions, reuse ALU with ALU source operands selection as pcE and 8
mux2 #(32) alusrcamux(srca2E, pcE, jbralE, srca3E);
mux2 #(32) alusrcbmux(srcb3E, 32'h00000008, jbralE, srcb4E);
// Forward CP0 write data before read data
mux2 #(32) forwardcp0mux(cp0_rdataE, aluoutM, (cp0_raddrE == cp0_waddrM), cp0_rdata2E);

alu alu(clk, rst, srca3E, srcb4E, alucontrolE, saE, read_hiloE, cp0_rdata2E, is_exceptM,
    write_hiloE, aluoutE, div_readyE, div_stallE, is_overflowE);
assign hilo_write2E = (alucontrolE == `EXE_DIV_OP | alucontrolE == `EXE_DIVU_OP) ?
    (div_readyE & hilo_writeE) : (hilo_writeE);
hilo_reg hilo_reg(clk, rst, (hilo_write2E & ~is_exceptM), write_hiloE, read_hiloE);
mux3 #(5) wrmux(rtE, rdE, 5'd31, regdstE, writeregE);

// Memory stage
floprc #(32) r1M(clk, rst, flushM, srcb2E, writedataM);
floprc #(32) r2M(clk, rst, flushM, aluoutE, aluoutM);
floprc #(5) r3M(clk, rst, flushM, writeregE, writeregM);
floprc #(6) r4M(clk, rst, flushM, opE, opM);
floprc #(5) r5M(clk, rst, flushM,
    {is_AdEL_pcE, is_syscallE, is_breakE, is_eretE, is_overflowE},
    {is_AdEL_pcM, is_syscallM, is_breakM, is_eretM, is_overflowM});
floprc #(1) r6M(clk, rst, flushM, is_in_delayslotE, is_in_delayslotM);
floprc #(32) r7M(clk, rst, flushM, pcE, pcM);
floprc #(5) r8M(clk, rst, flushM, cp0_waddrE, cp0_waddrM);

assign mem_enM = (~is_AdEL_dataM & ~is_AdESM); // Memory enable, preventing access to exception addresses
mem_control mem_control(opM, aluoutM, readdataM, final_read_dataM, writedataM, mem_write_dataM, mem_wenM, is_AdEL_dataM, is_AdESM);
except_detection except_detection(
    // Input
    .clk(clk),
    .rst(rst),
    .ext_int(ext_int),
    .cp0_status(cp0_statusM),
    .cp0_cause(cp0_causeM),
    .cp0_epc(cp0_epcM),
    .is_syscallM(is_syscallM),
    .is_breakM(is_breakM),
    .is_eretM(is_eretM),
    .is_AdEL_pcM(is_AdEL_pcM),
    .is_AdEL_dataM(is_AdEL_dataM),
    .is_AdESM(is_AdESM),
    .is_overflowM(is_overflowM),
    .is_invalidM(is_invalidM),
    // Output
    .is_except(is_exceptM),
    .except_type(except_typeM),
    .except_pc(except_pcM)
);
assign bad_addrM = is_AdEL_pcM ? pcM : aluoutM;
cp0_reg cp0_reg(
    // Input
    .clk(clk),
    .rst(rst),
    .we_i(cp0_writeM),
    .waddr_i(cp0_waddrM),
    .raddr_i(cp0_raddrE),
    .data_i(aluoutM),
    .int_i(ext_int),
    .excepttype_i(except_typeM),
    .current_inst_addr_i(pcM),
    .is_in_delayslot_i(is_in_delayslotM),
    .bad_addr_i(bad_addrM),
    // Output
    .data_o(cp0_rdataE),
    .count_o(cp0_countM),
    .compare_o(cp0_compareM),
    .status_o(cp0_statusM), // Used for interrupt handling
    .cause_o(cp0_causeM),   // Used for interrupt handling
    .epc_o(cp0_epcM),       // Used for ERET instruction
    .config_o(cp0_configM),
    .prid_o(cp0_pridM),
    .badvaddr(cp0_badvaddrM),
    .timer_int_o(cp0_timer_intM)
);

// Writeback stage
floprc #(32) r1W(clk, rst, flushW, aluoutM, aluoutW);
floprc #(32) r2W(clk, rst, flushW, final_read_dataM, readdataW);
floprc #(5) r3W(clk, rst, flushW, writeregM, writeregW);
mux2 #(32) resmux(aluoutW, readdataW, memtoregW, resultW);


endmodule
