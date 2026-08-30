`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: Greec Daher
// Project Name: UART 
//////////////////////////////////////////////////////////////////////////////////


module uart_baud_gen #(
    parameter CLK_FREQUENCY=100_000_000,
    parameter BAUD_RATE=115200
   )(
    input clk, 
    input reset, //active-high synchronous reset
    output reg tx_tick,
    output reg rx_tick
    );
    
    //integer division truncates but the error is small enough to neglect and it helps to keep TX/RX stay phase-locked to each other
    localparam CLK_PER_BIT = CLK_FREQUENCY/BAUD_RATE,
    CLK_CHUNK_16 = CLK_PER_BIT/16,
    WIDTH = $clog2(CLK_CHUNK_16); 
    
    reg [3:0] tx_counter;
    reg [WIDTH-1:0] rx_counter;
    
    always@(posedge clk) begin
        if(reset) begin
            tx_tick <= 0;
            rx_tick <= 0;
            tx_counter <= 4'h0;
            rx_counter <= 0;
        end
        
        else begin
            /* verilator lint_off WIDTHEXPAND */
            if (rx_counter==CLK_CHUNK_16- 1) begin 
            /* verilator lint_on WIDTHEXPAND */
                rx_counter <= 0;
                rx_tick <= 1;
                tx_counter <= (tx_counter==4'hf)?0:tx_counter + 'h1;
                tx_tick <= (tx_counter==4'hf);
            end
            else begin
                rx_counter <= rx_counter + 1'b1;
                rx_tick <= 0;
                tx_tick <= 0;
            end
        end
    end
    
endmodule
