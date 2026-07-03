`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 27.07.2025 20:22:53
// Design Name: 
// Module Name: uart_top
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

module uart_top(
    input        clk,             // System clock
    input        reset,
    input        rx,              // UART RX line
    input        tx_start,        // Trigger TX send
    input  [7:0] tx_data_in,      // Data to transmit
    input        read_all,        // Read all from RX FIFO
    input        mode,            // 0: flag at 8 bytes, 1: flag at 14 bytes
    output       tx,              // UART TX line
    output       tx_busy,         // Transmitter busy
    output       flag_ready,      // RX buffer ready (depends on mode)
    output [127:0] fifo_data_flat, // Flattened output from RX FIFO
    output       fifo_empty
);

    // Internal wires
    wire [7:0] rx_data;
    wire       rx_ready;
    wire       framing_error;
    wire       fifo_full;
    wire       baud_tick;
    wire       oversampling_tick;
    
    // NOTE: The pulse_sync module and its associated wire (rx_ready_sync) have been removed.

    // Instantiate Baud Generator
    baud_gen baud_inst (
        .clk(clk),
        .reset(reset),
        .baud_tick(baud_tick),
        .oversampling_tick(oversampling_tick)
    );

    // Instantiate UART Receiver
    // CORRECTED: Added the .clk connection
    uart_rx rx_inst (
        .clk(clk),
        .reset(reset),
        .rx(rx),
        .oversample_tick(oversampling_tick),
        .rx_data(rx_data),
        .rx_ready(rx_ready),
        .framing_error(framing_error)
    );

    // Instantiate UART Transmitter
    uart_tx tx_inst (
        .clk(clk),
        .data_clk(baud_tick),       // Use baud rate tick for TX
        .reset(reset),
        .start_tx(tx_start),
        .data_in(tx_data_in),
        .tx(tx),
        .tx_busy(tx_busy)
    );

    // Instantiate FIFO Buffer
    // CORRECTED: The wr_en is now driven directly by rx_ready
    FIFO_buffer fifo_inst (
        .clk(clk),
        .reset(reset),
        .wr_en(rx_ready),
        .wr_data(rx_data),
        .read_all(read_all),
        .mode(mode),
        .data_out_flat(fifo_data_flat),
        .flag_ready(flag_ready),
        .full(fifo_full),
        .empty(fifo_empty)
    );

endmodule
