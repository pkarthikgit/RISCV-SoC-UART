`timescale 1ns / 1ps

module register_file(
    input         clk,
    input         rst,
    input  [4:0]  read_reg_num1,    // rs1
    input  [4:0]  read_reg_num2,    // rs2
    input  [4:0]  write_reg_num,    // rd
    input  [31:0] write_data,       // Data to write
    input         reg_write,        // Write enable
    input  [31:0] mem_data,         // Data from memory
    input         lb,               // Load instruction
    input         lui_control,      // LUI instruction
    input  [31:0] lui_imm_val,      // LUI immediate
    input         jump,             // Jump instruction
    input  [31:0] return_address,   // Return address for JAL/JALR
    input         sw,               // Store instruction
    output [31:0] read_data1,       // rs1 output
    output [31:0] read_data2,       // rs2 output
    output [31:0] store_data        // Data for store operations
);

    // 32 registers of 32 bits each
    reg [31:0] registers [31:0];
    integer i;

    // Combinational read - register 0 is always 0
    assign read_data1 = (read_reg_num1 == 5'd0) ? 32'd0 : registers[read_reg_num1];
    assign read_data2 = (read_reg_num2 == 5'd0) ? 32'd0 : registers[read_reg_num2];
    assign store_data = read_data2; // For store operations, use rs2 data

    // Synchronous write
    always @(posedge clk) begin
        if (rst) begin
            // Initialize all registers to 0
            for (i = 0; i < 32; i = i + 1) begin
                registers[i] <= 32'd0;
            end
        end else begin
            // Write to register (but never to x0)
            if (reg_write && write_reg_num != 5'd0) begin
                if (lb) begin
                    // Load instruction - write memory data
                    registers[write_reg_num] <= mem_data;
                end else if (lui_control) begin
                    // LUI instruction - write upper immediate
                    registers[write_reg_num] <= lui_imm_val;
                end else if (jump) begin
                    // JAL/JALR instruction - write return address
                    registers[write_reg_num] <= return_address;
                end else begin
                    // Regular ALU operation - write ALU result
                    registers[write_reg_num] <= write_data;
                end
            end
        end
    end

endmodule
