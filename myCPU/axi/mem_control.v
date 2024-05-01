module mem_control(
    input wire[5:0] op_code,          // Instruction op_code
    input wire[31:0] addr,           // Memory address
    input wire[31:0] mem_read_data,  // Data read from data memory
    output reg[31:0] final_read_data,// Data to be written back to regfile
    input wire[31:0] pre_write_data, // Data read from the rt register
    output reg[31:0] mem_write_data, // Data to be written to data memory
    output reg [3:0] mem_wen,        // Byte write enable
    output reg is_AdELM,             // Load instruction address misalignment exception flag
    output reg is_AdESM              // Store instruction address misalignment exception flag
);

// Initialize control signals
always @(*) begin
    mem_wen = 4'b0000;
    is_AdELM = 1'b0;
    is_AdESM = 1'b0;

    case (op_code)
        // Load instructions
        `LB:  begin
            case (addr[1:0])
                2'b00: final_read_data = {{24{mem_read_data[7]}}, mem_read_data[7:0]};
                2'b01: final_read_data = {{24{mem_read_data[15]}}, mem_read_data[15:8]};
                2'b10: final_read_data = {{24{mem_read_data[23]}}, mem_read_data[23:16]};
                2'b11: final_read_data = {{24{mem_read_data[31]}}, mem_read_data[31:24]};
            endcase
        end
        `LBU:  begin
            case (addr[1:0])
                2'b00: final_read_data = {24'b0, mem_read_data[7:0]};
                2'b01: final_read_data = {24'b0, mem_read_data[15:8]};
                2'b10: final_read_data = {24'b0, mem_read_data[23:16]};
                2'b11: final_read_data = {24'b0, mem_read_data[31:24]};
            endcase
        end
        `LH:  begin
            case (addr[1:0])
                2'b00: final_read_data = {{16{mem_read_data[15]}}, mem_read_data[15:0]};
                2'b10: final_read_data = {{16{mem_read_data[31]}}, mem_read_data[31:16]};
                default: is_AdELM = 1'b1; // Mark address misalignment exception
            endcase
        end
        `LHU:  begin
            case (addr[1:0])
                2'b00: final_read_data = {16'b0, mem_read_data[15:0]};
                2'b10: final_read_data = {16'b0, mem_read_data[31:16]};
                default: is_AdELM = 1'b1; // Mark address misalignment exception
            endcase
        end
        `LW:  begin
            final_read_data = mem_read_data;
            if (~(addr[1:0] == 2'b00)) begin
                is_AdELM = 1'b1; // Mark address misalignment exception
            end
        end

        // Store instructions
        `SB:  begin
            case (addr[1:0])
                2'b00: mem_wen = 4'b0001;
                2'b01: mem_wen = 4'b0010;
                2'b10: mem_wen = 4'b0100;
                2'b11: mem_wen = 4'b1000;
            endcase
            mem_write_data = {4{pre_write_data[7:0]}};
        end
        `SH:  begin
            case (addr[1:0])
                2'b00: mem_wen = 4'b0011;
                2'b10: mem_wen = 4'b1100;
                default: is_AdESM = 1'b1; // Mark address misalignment exception
            endcase
            mem_write_data = {2{pre_write_data[15:0]}};
        end
        `SW:  begin
            mem_wen = 4'b1111;
            mem_write_data = pre_write_data;
            if (~(addr[1:0] == 2'b00)) begin
                is_AdESM = 1'b1; // Mark address misalignment exception
            end
        end
    endcase
end

endmodule
