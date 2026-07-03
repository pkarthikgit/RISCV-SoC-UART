`timescale 1ns / 1ps

module soc(
    input clk,
    input reset,
    input uart_rx_pin,
    output uart_tx_pin
);

    localparam UART_DATA_ADDR   = 32'h10000000;
    localparam UART_STATUS_ADDR = 32'h10000004;

    // Wires for the CPU's memory interface
    wire [31:0] cpu_mem_address;
    wire [31:0] cpu_mem_write_data;
    wire        cpu_mem_write_enable;
    wire        cpu_mem_read_enable;
    wire [31:0] cpu_mem_read_data_in; 

    // Wires for the UART's interface
    wire [127:0] uart_fifo_output; // <-- CHANGED: Was 8-bit 
    wire         uart_rx_fifo_ready;
    wire         uart_tx_is_busy;
    reg          uart_tx_start_pulse;
    
    // --- CHANGED: Added logic to clear the FIFO after a read ---
    wire is_reading_from_uart_data = cpu_mem_read_enable && (cpu_mem_address == UART_DATA_ADDR);
    reg  uart_read_ack_pulse;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            uart_read_ack_pulse <= 1'b0;
        end else begin
            uart_read_ack_pulse <= is_reading_from_uart_data;
        end
    end
    // -----------------------------------------------------------

    // Instantiate the RISC-V Core
    top_riscv cpu (
        .clk(clk),
        .reset(reset),
        .mem_address(cpu_mem_address),
        .mem_write_data(cpu_mem_write_data),
        .mem_write_enable(cpu_mem_write_enable),
        .mem_read_enable(cpu_mem_read_enable),
        .mem_read_data_in(cpu_mem_read_data_in)
    );
    
    // Instantiate the UART
    uart_top uart (
        .clk(clk),
        .reset(reset),
        .rx(uart_rx_pin),
        .tx(uart_tx_pin),
        .tx_start(uart_tx_start_pulse),
        .tx_data_in(cpu_mem_write_data[7:0]), 
        .read_all(uart_read_ack_pulse), // <-- CHANGED: Was 1'b0 
        .mode(1'b0),     
        .tx_busy(uart_tx_is_busy),
        .flag_ready(uart_rx_fifo_ready),
        .fifo_data_flat(uart_fifo_output), // <-- CHANGED: Connected to 128-bit wire 
        .fifo_empty(/* you can connect this if needed */)
    );
    
    // --- CHANGED: Added wire for RAM read data ---
    wire [31:0] ram_read_out;
    
    // Instantiate the Data Memory (RAM)
    data_memory ram (
        .clk(clk),
        .reset(reset),
        .read_addr(cpu_mem_address[4:0]), 
        .write_addr(cpu_mem_address[4:0]),
        .write_data(cpu_mem_write_data),
        .sw(is_writing_to_ram), // <-- CHANGED: Used the existing wire
        .read_data(ram_read_out) // <-- CHANGED: Was unconnected 
    );
    
    // Logic for handling CPU write operations
    wire is_writing_to_uart = cpu_mem_write_enable && (cpu_mem_address == UART_DATA_ADDR);
    wire is_writing_to_ram  = cpu_mem_write_enable && (cpu_mem_address < UART_DATA_ADDR); 
    
    // Connect the RAM's write enable
    // assign ram.sw = is_writing_to_ram; // <-- This is now done in the port connection
    
    // Generate a single-cycle pulse for the UART's tx_start signal
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            uart_tx_start_pulse <= 1'b0;
        end else begin
            uart_tx_start_pulse <= is_writing_to_uart;
        end
    end

    // Logic for handling CPU read operations using a MUX
    reg [31:0] read_data_mux;
    always @(*) begin
        case (cpu_mem_address)
            UART_DATA_ADDR:
                // When reading from the data address, provide the received byte from the FIFO
                read_data_mux = {24'd0, uart_fifo_output[7:0]}; // <-- CHANGED: Read from 128-bit wire's LSBs 
            UART_STATUS_ADDR:
                // When reading from the status address, provide the status bits
                read_data_mux = {30'd0, uart_tx_is_busy, uart_rx_fifo_ready};
            default:
                // For all other addresses, provide the data from RAM
                read_data_mux = ram_read_out; // <-- CHANGED: Was ram.read_data 
        endcase
    end
    
    // Connect the output of the MUX to the CPU's data input
    assign cpu_mem_read_data_in = read_data_mux;
    
endmodule
