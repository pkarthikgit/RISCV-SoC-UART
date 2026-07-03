`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 27.07.2025 00:31:52
// Design Name: 
// Module Name: FIFO_buffer
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: 
// Design: FIFO_buffer
//////////////////////////////////////////////////////////////////////////////////

module FIFO_buffer(
    input         clk,
    input         reset,
    input         wr_en,
    input  [7:0]  wr_data,
    input         read_all,
    input         mode,
    output [127:0] data_out_flat,
    output wire   flag_ready,  // <-- CHANGED from reg to wire
    output reg    full,
    output reg    empty
);
    reg [7:0] buffer [0:15];
    reg [3:0] wr_ptr;
    reg [4:0] count;
    integer i;
    
    // Flatten buffer to data_out_flat
    genvar idx;
    generate
        for (idx = 0; idx < 16; idx = idx + 1) begin : flatten
            assign data_out_flat[idx*8 +: 8] = buffer[idx];
        end
    endgenerate

    // ADD this continuous assign statement for flag_ready
    assign flag_ready = (mode == 1) ? (count >= 14) :
                        (mode == 0) ? (count >= 8)  : 0;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            wr_ptr <= 0;
            count  <= 0;
            full   <= 0;
            empty  <= 1;
            // REMOVED flag_ready from reset
            for (i = 0; i < 16; i = i + 1)
                buffer[i] <= 8'd0;
        end else begin
            // Write Logic
            if (wr_en && !full) begin
                buffer[wr_ptr] <= wr_data;
                wr_ptr <= wr_ptr + 1;
                count  <= count + 1;
            end

            // Read-all logic
            if (read_all && count > 0) begin
                wr_ptr <= 0;
                count  <= 0;
                full   <= 0;
                empty  <= 1;
                // REMOVED flag_ready assignment here
            end else begin
                // Status flags
                full  <= (count == 16);
                empty <= (count == 0);
                // REMOVED flag_ready assignment here
            end
        end
    end
endmodule
