`timescale 1ns / 1ps

module data_path(
    input         clk,
    input         rst,
    input  [4:0]  rs1,
    input  [4:0]  rs2,
    input  [4:0]  rd,
    input  [5:0]  alu_control,
    input         jump, beq_control, bne_control, bgeq_control, blt_control,
    input         reg_write,
    input         mem_to_reg,
    input         lb, sw, lui_control,
    input  [31:0] imm_i, imm_s, imm_b, imm_u, imm_j,
    input  [31:0] current_pc,
    
    // Ports for the memory system
    input  [31:0] mem_read_data_in, // Data coming FROM the memory system
    output [31:0] mem_address,      // Address FOR the memory system
    output [31:0] mem_write_data,   // Data going TO the memory system
    output        mem_write_enable, // The 'sw' signal
    output        mem_read_enable,  // The 'lb' (or any load) signal
    
    output        beq, bneq, bge, blt,
    output [31:0] alu_result,
    // output [31:0] mem_read_data, // <-- CHANGED: Removed this unused, confusing output
    output [31:0] next_pc,
    output [31:0] store_data,
    output [31:0] write_back_data
);

    // Internal wires
    wire [31:0] reg_data1, reg_data2;
    wire [31:0] pc_plus4 = current_pc + 4;

    // ALU source selection
    assign alu_src1 = reg_data1;
    
    // Memory interface connections
    assign mem_address = alu_result;      // The address for loads/stores is the ALU result
    assign mem_write_data = store_data;   // The data to be written is from the register file
    assign mem_write_enable = sw;         // The 'sw' control signal enables writes
    assign mem_read_enable = lb;          // The 'lb' control signal indicates a read

    // ALU second operand selection
    reg [31:0] alu_src2_mux;
    always @(*) begin
        case (alu_control)
            // Operations that use immediate operand
            6'b001011, 6'b001100, 6'b001101, 6'b001110, 6'b001111,
            6'b010000, 6'b010001, 6'b010010, 6'b010011, 6'b010101,
            6'b011000, 6'b011010: begin
                alu_src2_mux = imm_i; // Use I-type immediate
            end
            default: begin
                alu_src2_mux = reg_data2; // Use register operand
            end
        endcase
    end
    
    // Correct write-back data selection
    assign write_back_data = mem_to_reg ? mem_read_data_in : alu_result;
    
    assign alu_src2 = alu_src2_mux;

    // Register File
    register_file rf(
        .clk(clk),
        .rst(rst),
        .read_reg_num1(rs1),
        .read_reg_num2(rs2),
        .write_reg_num(rd),
        .write_data(write_back_data),
        .reg_write(reg_write),
        .mem_data(mem_read_data_in),
        .lb(lb),
        .lui_control(lui_control),
        .lui_imm_val(imm_u),
        .jump(jump),
        .return_address(pc_plus4),
        .sw(sw),
        .read_data1(reg_data1),
        .read_data2(reg_data2),
        .store_data(store_data)
    );
    
    // ALU
    alu alu_unit(
        .src1(alu_src1),
        .src2(alu_src2),
        .alu_control(alu_control),
        .imm_val_r(imm_i),
        .shamt(imm_i[3:0]),
        .result(alu_result)
    );
    
    // <-- CHANGED: Removed the duplicate 'write_back_data' assignment that was here
    
    // Branch logic
    assign beq  = (alu_result == 1) & beq_control;
    assign bneq = (alu_result == 1) & bne_control;
    assign bge  = (alu_result == 1) & bgeq_control;
    assign blt  = (alu_result == 1) & blt_control;

    // Next PC logic
    reg [31:0] next_pc_reg;
    always @(*) begin
        if (jump) begin
            next_pc_reg = current_pc + imm_j;
        end else if (beq | bneq | bge | blt) begin
            next_pc_reg = current_pc + imm_b;
        end else begin
            next_pc_reg = pc_plus4;
        end
    end

    assign next_pc = next_pc_reg;

endmodule
