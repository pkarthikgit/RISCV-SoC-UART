`timescale 1ns / 1ps

module uart_tx(
    input         clk,
    input         data_clk, // This is the baud_tick, used as an enable
    input         reset,
    input         start_tx,
    input  [7:0]  data_in,
    output reg    tx,
    output reg    tx_busy
);
    parameter IDLE = 3'b000, START_BIT = 3'b001, SEND_BITS = 3'b010, STOP_BIT = 3'b011;

    reg [2:0] current_state;
    reg [2:0] bit_index;
    reg [7:0] tx_data_reg;

    // This is the single, unified logic block for the entire module.
    // Everything is synchronous to the main system 'clk'.
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            tx <= 1;
            tx_busy <= 0;
            current_state <= IDLE;
            bit_index <= 0;
            tx_data_reg <= 8'h00;
        end else begin
            
            // The FSM controls all state transitions
            case (current_state)
                IDLE: begin
                    tx_busy <= 0;
                    tx <= 1; // Drive the line high when idle

                    // On a start pulse, immediately capture the data,
                    // assert busy, and move to the START_BIT state.
                    // This is responsive and happens on the fast 'clk'.
                    if (start_tx && !tx_busy) begin
                        tx_busy <= 1;
                        tx_data_reg <= data_in;
                        current_state <= START_BIT;
                    end
                end

                // The following states, which control the timing of each bit,
                // are only allowed to execute when enabled by the slower 'data_clk' tick.
                START_BIT: begin
                    if (data_clk) begin
                        tx <= 0; // Send the start bit (low)
                        bit_index <= 0;
                        current_state <= SEND_BITS;
                    end
                end

                SEND_BITS: begin
                    if (data_clk) begin
                        tx <= tx_data_reg[bit_index]; // Send the current data bit
                        if (bit_index == 7) begin
                            current_state <= STOP_BIT; // Move to stop bit after the last data bit
                        end else begin
                            bit_index <= bit_index + 1;
                        end
                    end
                end

                STOP_BIT: begin
                    if (data_clk) begin
                        tx <= 1; // Send the stop bit (high)
                        current_state <= IDLE; // Return to idle
                        // tx_busy will be de-asserted on the next clock cycle when the state is IDLE.
                    end
                end

                default: begin
                    current_state <= IDLE;
                end
            endcase
        end
    end
endmodule
