`timescale 1ps/1ps

// ============================================================================
// RISC-V 单周期 CPU - 访存阶段 (Memory Access Stage)
// 通过 DPI-C dpi_mem_read / dpi_mem_write 进行内存访问
// C 接口:
//   uint32_t dpi_mem_read(uint32_t addr, int len, uint64_t pc)
//   void     dpi_mem_write(uint32_t addr, uint32_t data, int len, uint64_t pc)
// len: 字节数 (LB/SB=1, LH/SH=2, LW/SW=4)
// ============================================================================

module memory_access(
    // Clock
    input wire        clk,

    // Input signals from Execute stage
    input wire [6:0]  opcode_i,
    input wire [2:0]  funct3_i,
    input wire [31:0] alu_result_i,   // 地址 (rs1 + imm)
    input wire [31:0] rs2_data_i,     // 写入数据 (Store)
    input wire [31:0] PC_i,           // 当前 PC（传给 DPI-C）

    // Output signals
    output reg [31:0] mem_data_o      // 从内存读出的数据
);

    // ==================== DPI-C 声明 ====================
    import "DPI-C" function int  dpi_mem_read (input int addr, input int len, input longint unsigned pc);
    import "DPI-C" function void dpi_mem_write(input int addr, input int data, int len, longint unsigned pc);

    // 操作码定义
    localparam OP_LOAD  = 7'b0000011;
    localparam OP_STORE = 7'b0100011;

    // ==================== 访存宽度 (字节数) ====================
    // funct3[1:0]: 00 → 1 byte, 01 → 2 bytes, 10 → 4 bytes
    reg [31:0] byte_len;
    always @(*) begin
        case (funct3_i[1:0])
            2'b00: byte_len = 32'd1;
            2'b01: byte_len = 32'd2;
            2'b10: byte_len = 32'd4;
            default: byte_len = 32'd4;
        endcase
    end

    // ==================== 组合读（LOAD） ====================
    reg [31:0] raw_mem_data;
    
    always @(*) begin
        if (opcode_i == OP_LOAD) begin
            raw_mem_data = dpi_mem_read(alu_result_i, byte_len, {32'd0, PC_i});
            
            case (funct3_i)
                3'b000: mem_data_o = {{24{raw_mem_data[7]}}, raw_mem_data[7:0]};    // LB: sign-extend byte
                3'b001: mem_data_o = {{16{raw_mem_data[15]}}, raw_mem_data[15:0]};  // LH: sign-extend halfword
                3'b010: mem_data_o = raw_mem_data;                                   // LW: word
                3'b100: mem_data_o = {24'b0, raw_mem_data[7:0]};                     // LBU: zero-extend byte
                3'b101: mem_data_o = {16'b0, raw_mem_data[15:0]};                    // LHU: zero-extend halfword
                default: mem_data_o = raw_mem_data;
            endcase
        end else begin
            raw_mem_data = 32'd0;
            mem_data_o = 32'd0;
        end
    end

    // ==================== 时序写（STORE） ====================
    always @(posedge clk) begin
        if (opcode_i == OP_STORE) begin
            dpi_mem_write(alu_result_i, rs2_data_i, byte_len, {32'd0, PC_i});
        end
    end

endmodule
