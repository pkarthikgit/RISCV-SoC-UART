`timescale 1ns / 1ps

module baud_gen (
    input clk,
    input reset,
    output reg baud_tick,
    output reg oversampling_tick
);
    parameter CLOCK_RATE = 15360000;
    parameter BAUD_RATE = 9600;

    localparam BAUD_DIV = CLOCK_RATE / BAUD_RATE;        // 1600
    localparam OVERSAMPLE_DIV = BAUD_DIV / 16;          // 100

    reg [6:0] oversample_counter;  // 7 bits for 0-99
    reg [3:0] bit_tick_counter;    // 4 bits for 0-15

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            bit_tick_counter <= 0;
            oversample_counter <= 0;
            baud_tick <= 0;
            oversampling_tick <= 0;
        end else begin
            // Increment oversample counter
            if (oversample_counter == OVERSAMPLE_DIV - 1) begin
                oversample_counter <= 0;
                oversampling_tick <= 1;
                
                // Increment bit tick counter when oversample completes
                if (bit_tick_counter == 15) begin
                    bit_tick_counter <= 0;
                    baud_tick <= 1;          // Generate baud tick pulse
                end else begin
                    bit_tick_counter <= bit_tick_counter + 1;
                    baud_tick <= 0;          // Explicitly clear when not pulsing
                end
            end else begin
                oversample_counter <= oversample_counter + 1;
                oversampling_tick <= 0;      // Clear oversampling tick
                baud_tick <= 0;              // Clear baud tick
            end
        end
    end

endmodule
