module top_riscv_fetch_test(
    input clk,
    input reset,
    output [31:0] pc,
    output [31:0] instruction_code
);

    wire [31:0] next_pc;
    wire pc_enable = 1'b1;

    assign next_pc = pc + 4;

    instruction_fetch_unit IFU (
        .clk(clk),
        .reset(reset),
        .next_pc(next_pc),
        .pc_enable(pc_enable),
        .pc(pc),
        .pc_plus4()
    );

    instruction_memory IMEM (
        .clk(clk),
        .pc(pc),
        .reset(reset),
        .instruction_code(instruction_code)
    );
endmodule
