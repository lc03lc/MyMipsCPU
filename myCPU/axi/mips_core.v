`timescale 1ns / 1ps

module mycpu_top(
    input [5:0] ext_int,   // High-active input

    input wire aclk,    
    input wire aresetn,   // Low-active reset

    output wire[3:0] arid,
    output wire[31:0] araddr,
    output wire[7:0] arlen,
    output wire[2:0] arsize,
    output wire[1:0] arburst,
    output wire[1:0] arlock,
    output wire[3:0] arcache,
    output wire[2:0] arprot,
    output wire arvalid,
    input wire arready,
                
    input wire[3:0] rid,
    input wire[31:0] rdata,
    input wire[1:0] rresp,
    input wire rlast,
    input wire rvalid,
    output wire rready, 
               
    output wire[3:0] awid,
    output wire[31:0] awaddr,
    output wire[7:0] awlen,
    output wire[2:0] awsize,
    output wire[1:0] awburst,
    output wire[1:0] awlock,
    output wire[3:0] awcache,
    output wire[2:0] awprot,
    output wire awvalid,
    input wire awready,
    
    output wire[3:0] wid,
    output wire[31:0] wdata,
    output wire[3:0] wstrb,
    output wire wlast,
    output wire wvalid,
    input wire wready,
    
    input wire[3:0] bid,
    input wire[1:0] bresp,
    input bvalid,
    output bready,

    // Debug interface
    output wire[31:0] debug_wb_pc,
    output wire[3:0] debug_wb_rf_wen,
    output wire[4:0] debug_wb_rf_wnum,
    output wire[31:0] debug_wb_rf_wdata
);

wire clk, rst;
assign clk = aclk;
assign rst = ~aresetn;

// AXI interface signals
wire        cpu_inst_req  ; // Instruction request
wire [31:0] cpu_inst_addr ; // Instruction address
wire        cpu_inst_wr   ; // Instruction write signal
wire [1:0]  cpu_inst_size ; // Instruction size
wire [31:0] cpu_inst_wdata; // Instruction write data
wire [31:0] cpu_inst_rdata; // Instruction read data
wire        cpu_inst_addr_ok; // Instruction address valid
wire        cpu_inst_data_ok; // Instruction data valid

wire        cpu_data_req  ; // Data request
wire [31:0] cpu_data_addr ; // Data address
wire        cpu_data_wr   ; // Data write signal
wire [1:0]  cpu_data_size ; // Data size
wire [31:0] cpu_data_wdata; // Data write data
wire [31:0] cpu_data_rdata; // Data read data
wire        cpu_data_addr_ok; // Data address valid
wire        cpu_data_data_ok; // Data valid

// Other signals
wire        cache_inst_req  ; // Cache instruction request
wire [31:0] cache_inst_addr ; // Cache instruction address
wire        cache_inst_wr   ; // Cache instruction write signal
wire [1:0]  cache_inst_size ; // Cache instruction size
wire [31:0] cache_inst_wdata; // Cache instruction write data
wire [31:0] cache_inst_rdata; // Cache instruction read data
wire        cache_inst_addr_ok; // Cache instruction address valid
wire        cache_inst_data_ok; // Cache instruction data valid

// Data cache signals
wire        cache_data_req  ; // Cache data request
wire [31:0] cache_data_addr ; // Cache data address
wire        cache_data_wr   ; // Cache data write signal
wire [1:0]  cache_data_size ; // Cache data size
wire [31:0] cache_data_wdata; // Cache data write data
wire [31:0] cache_data_rdata; // Cache data read data
wire        cache_data_addr_ok; // Cache data address valid
wire        cache_data_data_ok; // Cache data valid

// RAM signals
wire        ram_data_req  ; // RAM data request
wire [31:0] ram_data_addr ; // RAM data address
wire        ram_data_wr   ; // RAM data write signal
wire [1:0]  ram_data_size ; // RAM data size
wire [31:0] ram_data_wdata; // RAM data write data
wire [31:0] ram_data_rdata; // RAM data read data
wire        ram_data_addr_ok; // RAM data address valid
wire        ram_data_data_ok; // RAM data valid

// Configuration memory signals
wire        conf_data_req  ; // Configuration data request
wire [31:0] conf_data_addr ; // Configuration data address
wire        conf_data_wr   ; // Configuration data write signal
wire [1:0]  conf_data_size ; // Configuration data size
wire [31:0] conf_data_wdata; // Configuration data write data
wire [31:0] conf_data_rdata; // Configuration data read data
wire        conf_data_addr_ok; // Configuration data address valid
wire        conf_data_data_ok; // Configuration data valid

// Wrapper memory signals
wire        wrap_data_req  ; // Wrapper data request
wire [31:0] wrap_data_addr ; // Wrapper data address
wire        wrap_data_wr   ; // Wrapper data write signal
wire [1:0]  wrap_data_size ; // Wrapper data size
wire [31:0] wrap_data_wdata; // Wrapper data write data
wire [31:0] wrap_data_rdata; // Wrapper data read data
wire        wrap_data_addr_ok; // Wrapper data address valid
wire        wrap_data_data_ok; // Wrapper data valid

// Instantiate MIPS core
mips_core  mips_core(
    .clk(clk), .rst(rst),
    .ext_int(ext_int),

    .inst_req     (cpu_inst_req  ),
    .inst_wr      (cpu_inst_wr   ),
    .inst_addr    (cpu_inst_addr ),
    .inst_size    (cpu_inst_size ),
    .inst_wdata   (cpu_inst_wdata),
    .inst_rdata   (cpu_inst_rdata),
    .inst_addr_ok (cpu_inst_addr_ok),
    .inst_data_ok (cpu_inst_data_ok),

    .data_req     (cpu_data_req  ),
    .data_wr      (cpu_data_wr   ),
    .data_addr    (cpu_data_addr ),
    .data_wdata   (cpu_data_wdata),
    .data_size    (cpu_data_size ),
    .data_rdata   (cpu_data_rdata),
    .data_addr_ok (cpu_data_addr_ok),
    .data_data_ok (cpu_data_data_ok),

    .debug_wb_pc       (debug_wb_pc       ),
    .debug_wb_rf_wen   (debug_wb_rf_wen   ),
    .debug_wb_rf_wnum  (debug_wb_rf_wnum  ),
    .debug_wb_rf_wdata (debug_wb_rf_wdata )
);

// Signals for instruction and data SRAM-like memory
wire inst_sram_en           ;
wire [31:0] inst_sram_addr  ;
wire [31:0] inst_sram_rdata ;
wire i_stall                ;

wire data_sram_en           ;
wire [31:0] data_sram_addr  ;
wire [31:0] data_sram_rdata ;
wire [3:0] data_sram_wen    ;
wire [31:0] data_sram_wdata ;
wire d_stall                ;

wire longest_stall;

// Instantiate MIPS CPU core
mips mips(
    .clk(clk), .rst(rst),
    .ext_int(ext_int),

    // Instruction fetch signals
    .pcF(inst_sram_addr),
    .instr_enF(inst_sram_en),
    .instrF(inst_sram_rdata),
    .i_stall(i_stall),

    // Data access signals
    .mem_enM(data_sram_en),
    .aluoutM(data_sram_addr),
    .readdataM(data_sram_rdata),
    .mem_wenM(data_sram_wen),
    .mem_write_dataM(data_sram_wdata),
    .d_stall(d_stall),

    .longest_stall(longest_stall),

    // Debugging signals
    .debug_wb_pc       (debug_wb_pc       ),  
    .debug_wb_rf_wen   (debug_wb_rf_wen   ),  
    .debug_wb_rf_wnum  (debug_wb_rf_wnum  ),  
    .debug_wb_rf_wdata (debug_wb_rf_wdata )  
);

// Instruction cache
i_cache i_cache(
    .clk(clk), .rst(rst),
    // SRAM-like signals
    .inst_sram_en(inst_sram_en),
    .inst_sram_addr(inst_sram_addr),
    .inst_sram_rdata(inst_sram_rdata),
    .i_stall(i_stall),
    // Cache-like signals
    .inst_req(inst_req), 
    .inst_wr(inst_wr),
    .inst_size(inst_size),
    .inst_addr(inst_addr),   
    .inst_wdata(inst_wdata),
    .inst_addr_ok(inst_addr_ok),
    .inst_data_ok(inst_data_ok),
    .inst_rdata(inst_rdata),

    .longest_stall(longest_stall)
);

// Data cache
d_cache d_cache(
    .clk(clk), .rst(rst),
    // SRAM-like signals
    .data_sram_en(data_sram_en),
    .data_sram_addr(data_sram_addr),
    .data_sram_rdata(data_sram_rdata),
    .data_sram_wen(data_sram_wen),
    .data_sram_wdata(data_sram_wdata),
    .d_stall(d_stall),
    // Cache-like signals
    .data_req(data_req),    
    .data_wr(data_wr),
    .data_size(data_size),
    .data_addr(data_addr),   
    .data_wdata(data_wdata),
    .data_addr_ok(data_addr_ok),
    .data_data_ok(data_data_ok),
    .data_rdata(data_rdata),

    .longest_stall(longest_stall)
);

endmodule
