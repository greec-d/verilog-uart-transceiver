`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: Greec Daher
// Project Name: UART 
//////////////////////////////////////////////////////////////////////////////////


module uart_top #(
    parameter CLK_FREQUENCY = 100_000_000,
    parameter BAUD_RATE = 115200
)(
    input clk,
    input reset,

    // RX interface
    input rx_in,
    output [7:0] rx_data,
    output frame_err,
    output rx_busy,

    // TX interface
    input [7:0] tx_data,
    input tx_start,
    output tx_out,
    output tx_busy
);

    wire rx_tick;
    wire tx_tick;
    
    //Instantiate a baud_gen
    uart_baud_gen #(
        .CLK_FREQUENCY(CLK_FREQUENCY),
        .BAUD_RATE(BAUD_RATE)
    ) baud_gen_instant (
        .clk(clk),
        .reset(reset),
        .tx_tick(tx_tick),
        .rx_tick(rx_tick)
    );
    
    //Instantiate an rx module
    uart_rx rx_instant (
        .clk(clk),
        .reset(reset),
        .rx_tick(rx_tick),
        .rx_in(rx_in),
        .rx_data(rx_data),
        .frame_err(frame_err),
        .rx_busy(rx_busy)
    );
    
    //Instantiate a tx module
    uart_tx tx_instant (
        .clk(clk),
        .reset(reset),
        .tx_data(tx_data),
        .tx_tick(tx_tick),
        .tx_start(tx_start),
        .tx_out(tx_out),
        .tx_busy(tx_busy)
    );
endmodule
