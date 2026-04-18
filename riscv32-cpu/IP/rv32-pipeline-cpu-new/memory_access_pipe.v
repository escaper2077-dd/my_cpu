`timescale 1ps/1ps

// ============================================================================
// RISC-V 五级流水线 CPU - 访存阶段 (MEM Stage)
// 通过 DPI-C 进行内存读写
// ============================================================================

module memory_access_pipe(
    input wire        clk,

    input wire [6:0]  opcode_i,
    input wire [2:0]  funct3_i,
    input wire [31:0] alu_result_i,   // 地址
    input wire [31:0] rs2_data_i,     // Store 数据
    input wire [31:0] pc_i,

    output reg [31:0] mem_data_o
);

    import "DPI-C" function int  dpi_mem_read (input int addr, input int len, input longint unsigned pc);
    import "DPI-C" function void dpi_mem_write(input int addr, input int data, int len, longint unsigned pc);

    localparam OP_LOAD  = 7'b0000011;
    localparam OP_STORE = 7'b0100011;

    // 访存宽度
    reg [31:0] byte_len;
    always @(*) begin
        case (funct3_i[1:0])
            2'b00:   byte_len = 32'd1;
            2'b01:   byte_len = 32'd2;
            2'b10:   byte_len = 32'd4;
            default: byte_len = 32'd4;
        endcase
    end

    // 组合读
    reg [31:0] raw_mem_data;
    always @(*) begin
        if (opcode_i == OP_LOAD) begin
            raw_mem_data = dpi_mem_read(alu_result_i, byte_len, {32'd0, pc_i});
            case (funct3_i)
                3'b000:  mem_data_o = {{24{raw_mem_data[7]}},  raw_mem_data[7:0]};
                3'b001:  mem_data_o = {{16{raw_mem_data[15]}}, raw_mem_data[15:0]};
                3'b010:  mem_data_o = raw_mem_data;
                3'b100:  mem_data_o = {24'b0, raw_mem_data[7:0]};
                3'b101:  mem_data_o = {16'b0, raw_mem_data[15:0]};
                default: mem_data_o = raw_mem_data;
            endcase
        end else begin
            raw_mem_data = 32'd0;
            mem_data_o   = 32'd0;
        end
    end

    // 时序写
    always @(posedge clk) begin
        if (opcode_i == OP_STORE)
            dpi_mem_write(alu_result_i, rs2_data_i, byte_len, {32'd0, pc_i});
    end

endmodule
