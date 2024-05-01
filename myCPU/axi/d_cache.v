module d_cache(
    input wire clk, rst,
    // SRAM
    input wire data_sram_en,
    input wire [31:0] data_sram_addr,
    output wire [31:0] data_sram_rdata,
    input wire [3:0] data_sram_wen,
    input wire [31:0] data_sram_wdata,
    output wire d_stall,

    // SRAM-like
    output wire data_req,    //
    output wire data_wr,
    output wire [1:0] data_size,
    output wire [31:0] data_addr,   
    output wire [31:0] data_wdata,

    input wire [31:0] data_rdata,
    input wire data_addr_ok,
    input wire data_data_ok,

    input wire longest_stall
);
    reg addr_rcv;      // Address handshake successful
    reg do_finish;     // End of read/write transaction

    always @(posedge clk) begin
        addr_rcv <= rst          ? 1'b0 :
                    data_req & data_addr_ok & ~data_data_ok ? 1'b1 :    // Ensure data_req before addr_rcv; If addr_ok and data_ok occur simultaneously, prioritize data_ok
                    data_data_ok ? 1'b0 : addr_rcv;
    end

    always @(posedge clk) begin
        do_finish <= rst          ? 1'b0 :
                     data_data_ok ? 1'b1 :
                     ~longest_stall ? 1'b0 : do_finish;
    end

    // Save rdata
    reg [31:0] data_rdata_save;
    always @(posedge clk) begin
        data_rdata_save <= rst ? 32'b0:
                           data_data_ok ? data_rdata : data_rdata_save;
    end

    // SRAM-like
    assign data_req = data_sram_en & ~addr_rcv & ~do_finish;
    assign data_wr = data_sram_en & |data_sram_wen;
    assign data_size = (data_sram_wen==4'b0001 || data_sram_wen==4'b0010 || data_sram_wen==4'b0100 || data_sram_wen==4'b1000) ? 2'b00:
                       (data_sram_wen==4'b0011 || data_sram_wen==4'b1100 ) ? 2'b01 : 2'b10;
    assign data_addr = data_sram_addr;
    assign data_wdata = data_sram_wdata;

    // SRAM
    assign data_sram_rdata = data_rdata_save;
    assign d_stall = data_sram_en & ~do_finish;
endmodule
