`timescale 1ns / 1ps

module top_riscv(
    input clk,
    input reset,

    // === CHANGED: Added Memory Interface Ports ===
    output [31:0] mem_address,
    output [31:0] mem_write_data,
    output        mem_write_enable,
    output        mem_read_enable,
    input  [31:0] mem_read_data_in,
    // ===========================================

    // === Outputs for testbench/debugging ===
    output [31:0] current_pc,
    output [31:0] instruction_code,
    output [4:0]  rs1, rs2, rd,
    output [6:0]  funct7, opcode,
    output [2:0]  funct3,
    output [31:0] imm_i, imm_s, imm_b, imm_u, imm_j,
    output [31:0] alu_result,
    output [31:0] write_back_data,
    // output [31:0] mem_read_data, // <-- CHANGED: Removed, now part of interface
    output [31:0] store_data,
    output [31:0] next_pc,
    output        beq, bneq, bge, blt
);
    // === Program Counter ===
    reg [31:0] pc;
    assign current_pc = pc;
    always @(posedge clk or posedge reset) begin
        if (reset)
            pc <= 0;
        else
            pc <= next_pc;
    end

    // === Instruction Fetch ===
    instruction_memory imem (
        .clk(clk),
        .pc(pc),
        .reset(reset),
        .instruction_code(instruction_code)
    );
    
    // === Instruction Decode ===
    assign opcode  = instruction_code[6:0];
    assign rd      = instruction_code[11:7];
    assign funct3  = instruction_code[14:12];
    assign rs1     = instruction_code[19:15];
    assign rs2     = instruction_code[24:20];
    assign funct7  = instruction_code[31:25];

    // === Immediate Generators ===
    assign imm_i = {{20{instruction_code[31]}}, instruction_code[31:20]};
    assign imm_s = {{20{instruction_code[31]}}, instruction_code[31:25], instruction_code[11:7]};
    assign imm_b = {{19{instruction_code[31]}}, instruction_code[31], instruction_code[7], instruction_code[30:25], instruction_code[11:8], 1'b0};
    assign imm_u = {instruction_code[31:12], 12'b0};
    assign imm_j = {{11{instruction_code[31]}}, instruction_code[31], instruction_code[19:12], instruction_code[20], instruction_code[30:21], 1'b0};

    // === Control Unit ===
    wire [5:0] alu_control;
    wire lb, mem_to_reg, bneq_control, beq_control, bgeq_control, blt_control, jump, sw, lui_control, reg_write;
    control_unit cu (
        .reset(reset),
        .funct7(funct7),
        .funct3(funct3),
        .opcode(opcode),
        .alu_control(alu_control),
        .lb(lb),
        .mem_to_reg(mem_to_reg),
        .bneq_control(bneq_control),
        .beq_control(beq_control),
        .bgeq_control(bgeq_control),
        .blt_control(blt_control),
        .jump(jump),
        .sw(sw),
        .lui_control(lui_control),
        .reg_write(reg_write)
    );
    
    // === Data Path ===
    data_path dp (
        .clk(clk),
        .rst(reset),
        .rs1(rs1),
        .rs2(rs2),
        .rd(rd),
        .alu_control(alu_control),
        .jump(jump),
        .beq_control(beq_control),
        .bne_control(bneq_control),
        .bgeq_control(bgeq_control),
        .blt_control(blt_control),
        .reg_write(reg_write),
        .mem_to_reg(mem_to_reg),
        .lb(lb),
        .sw(sw),
        .lui_control(lui_control),
        .imm_i(imm_i),
        .imm_s(imm_s),
        .imm_b(imm_b),
        .imm_u(imm_u),
        .imm_j(imm_j),
        .current_pc(pc),
        
        // === CHANGED: Connected memory interface to data_path ===
        .mem_read_data_in(mem_read_data_in),
        .mem_address(mem_address),
        .mem_write_data(mem_write_data),
        .mem_write_enable(mem_write_enable),
        .mem_read_enable(mem_read_enable),
        // =======================================================
        
        .beq(beq),
        .bneq(bneq),
        .bge(bge),
        .blt(blt),
        .alu_result(alu_result),
        // .mem_read_data(mem_read_data), // <-- CHANGED: Removed
        .next_pc(next_pc),
        .store_data(store_data),
        .write_back_data(write_back_data)
    );
endmodule
