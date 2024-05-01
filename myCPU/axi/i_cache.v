module i_cache (
    input wire clk, rst,
    // SRAM
    input wire inst_sram_en,
    input wire [31:0] inst_sram_addr,
    output wire [31:0] inst_sram_rdata,
    output wire i_stall,
    // SRAM-like
    output wire inst_req, //
    output wire inst_wr,
    output wire [1:0] inst_size,
    output wire [31:0] inst_addr,
    output wire [31:0] inst_wdata,
    input wire inst_addr_ok,
    input wire inst_data_ok,
    input wire [31:0] inst_rdata,

    input wire longest_stall
);
    reg addr_rcv;      // Address handshake successful
    reg do_finish;     // End of read transaction

    always @(posedge clk) begin
        addr_rcv <= rst          ? 1'b0 :
                    inst_req & inst_addr_ok & ~inst_data_ok ? 1'b1 :    // Ensure inst_req before addr_rcv; If addr_ok and data_ok occur simultaneously, prioritize data_ok
                    inst_data_ok ? 1'b0 : addr_rcv;
    end

    always @(posedge clk) begin
        do_finish <= rst          ? 1'b0 :
                     inst_data_ok ? 1'b1 :
                     ~longest_stall ? 1'b0 : do_finish;
    end

    // Save rdata
    reg [31:0] inst_rdata_save;
    always @(posedge clk) begin
        inst_rdata_save <= rst ? 32'b0:
                           inst_data_ok ? inst_rdata : inst_rdata_save;
    end

    // SRAM-like
    assign inst_req = inst_sram_en & ~addr_rcv & ~do_finish;
    assign inst_wr = 1'b0;
    assign inst_size = 2'b10;
    assign inst_addr = inst_sram_addr;
    assign inst_wdata = 32'b0;

    // SRAM
    assign inst_sram_rdata = inst_rdata_save;
    assign i_stall = inst_sram_en & ~do_finish;
endmodule
