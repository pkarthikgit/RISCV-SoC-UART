`timescale 1ns / 1ps

// The clk input has been added to the port list
module uart_rx(
    input clk,
    input reset,
    input rx,
    input oversample_tick,
    output reg [7:0] rx_data,
    output reg rx_ready,
    output reg framing_error
);
    
    parameter IDLE = 3'b000, START_BIT = 3'b001, RECEIVE_BITS = 3'b010, STOP_BIT = 3'b011, DONE = 3'b100;
    
    reg [2:0] current_state;
    reg [2:0] bit_index;
    reg [3:0] counter;

    // A 2-flop synchronizer to safely bring the async 'rx' signal into the 'clk' domain
    reg rx_sync1;
    reg rx_sync2;
   
  
    always @(posedge clk or posedge reset) begin
		if (reset) begin
			rx_data <= 8'd0;
			rx_ready <= 0;
			bit_index <= 3'b000;
			counter <= 4'd0;
			current_state <= IDLE;
			framing_error <= 0;
            // The synchronizer must also be reset
            rx_sync1 <= 1;
            rx_sync2 <= 1;
		end else begin
		  	
		  	// This synchronizer logic runs on every single 'clk' cycle
            rx_sync1 <= rx;
            rx_sync2 <= rx_sync1;

            // The original FSM is now wrapped in an 'if (oversample_tick)' block,
            // so it only executes when enabled by the slower tick.
            if (oversample_tick) begin
                // Default output values
                rx_ready <= 0;
                if (current_state != IDLE) begin
                    if (counter == 15) begin
                        counter <= 0;
                    end else begin
                        counter <= counter + 1;
                    end
                end
                
                case(current_state)
                    IDLE: begin
                        // Wait for a start bit (falling edge)
                        // Use the new, safe 'rx_sync2' signal instead of the raw 'rx' input
                        if (~rx_sync2) begin
                            current_state <= START_BIT;
                            counter <= 0;
                            framing_error <= 0;
                        end
                    end
                    
                    START_BIT: begin
                        // Check the middle of the start bit
                        if (counter == 8) begin
                            // Check the synchronized 'rx_sync2'
                            if (rx_sync2) begin // If it's high, it was a glitch
                                current_state <= IDLE;
                            end
                        end else if (counter == 15) begin
                            current_state <= RECEIVE_BITS;
                            bit_index <= 0;
                            rx_data <= 8'h00; 
                        end
                    end
                    
                    RECEIVE_BITS: begin
                        // Sample the data bit in the middle using 'rx_sync2'
                        if (counter == 8) begin
                            rx_data[bit_index] <= rx_sync2;
                        end else if (counter == 15) begin
                            if (bit_index == 7) begin
                                current_state <= STOP_BIT;
                            end else begin
                                bit_index <= bit_index + 1;
                            end
                        end
                    end
                                    
                    STOP_BIT: begin
                        // Check the stop bit in the middle using 'rx_sync2'
                        if (counter == 8) begin
                            if (~rx_sync2) begin // Stop bit should be high
                                framing_error <= 1;
                            end
                        end else if (counter == 15) begin
                            current_state <= DONE;
                        end
                    end
                    
                    DONE: begin
                        rx_ready <= 1;
                        current_state <= IDLE;
                    end
                    
                    default: begin
                        current_state <= IDLE;
                    end
                endcase
            end // end if(oversample_tick)
		end
    end
endmodule
