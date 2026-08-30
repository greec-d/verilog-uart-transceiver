`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: Greec Daher
// Project Name: UART 
//////////////////////////////////////////////////////////////////////////////////


module tb_uart_top;

    reg clk;
    reg reset; //active-high synchronous reset
    
    reg [7:0] tx_data; //data transmitted
    reg tx_start;
    wire tx_out;
    wire tx_busy;
    
    wire [7:0] rx_data; //data received
    wire frame_err;
    wire rx_busy;
    reg rx_in;
    
    //GIVEN VARIABLES
    localparam TB_CLK_FREQUENCY = 100_000_000;
    localparam TB_BAUD_RATE = 115200;
        
    //CALCULATED VARIABLES   
    localparam TB_CLK_PERIOD = 1_000_000_000 / TB_CLK_FREQUENCY; //the clk to be generated
    localparam TB_CLK_PER_BIT = TB_CLK_FREQUENCY / TB_BAUD_RATE; //clock cycles per one bit 
    localparam TB_BIT_PERIOD  = (TB_CLK_PER_BIT / 16) * 16; //what the DUT actually produces accurately
     
    //Instantiate a uart_top module to test 
    uart_top #(
        .CLK_FREQUENCY(100_000_000),
        .BAUD_RATE(115200)
    ) uut (
        .clk(clk),
        .reset(reset),
    
        .rx_in(rx_in),
        .rx_data(rx_data),
        .frame_err(frame_err),
        .rx_busy(rx_busy),
    
        .tx_data(tx_data),
        .tx_start(tx_start),
        .tx_out(tx_out),
        .tx_busy(tx_busy)
    );
    
    //Generate a system clock based on the TB_CLK_PERIOD
     initial begin
         clk = 0;
         forever #(TB_CLK_PERIOD/2) clk = ~clk;
     end
    
    initial begin
        tx_start = 0;
        rx_in = 1;
        
        reset = 1;
        #60 reset = 0;
        
        //Test reset/idle states
        tx_start = 0;
        tx_data  = 8'h00;
    
        reset = 1;
    
        @(posedge clk);
        #1;
    
        $display("UART reset/idle state: %s", (!tx_busy && !rx_busy && tx_out && rx_data == 8'h00 && !frame_err) ? "PASS" : "FAIL");
        reset = 0;
    
        //Test tx transmission
        tx_data = 8'b1010_0011;
        tx_start = 1;
        
        @(posedge clk);
        tx_start = 0;
        
        wait(tx_busy);
        wait(!tx_busy);
        
        $display("UART TX transmission: %s", (!tx_busy && tx_out) ? "PASS" : "FAIL");
        
        //Test rx receiving 

        rx_in = 0;  // START bit
        repeat(TB_BIT_PERIOD) @(posedge clk);
        
        rx_in = 1;  // bit 0
        repeat(TB_BIT_PERIOD) @(posedge clk);
        
        rx_in = 1;  // bit 1
        repeat(TB_BIT_PERIOD) @(posedge clk);
        
        rx_in = 0;  // bit 2
        repeat(TB_BIT_PERIOD) @(posedge clk);
        
        rx_in = 0;  // bit 3
        repeat(TB_BIT_PERIOD) @(posedge clk);
        
        rx_in = 0;  // bit 4
        repeat(TB_BIT_PERIOD) @(posedge clk);
        
        rx_in = 1;  // bit 5
        repeat(TB_BIT_PERIOD) @(posedge clk);
        
        rx_in = 0;  // bit 6
        repeat(TB_BIT_PERIOD) @(posedge clk);
        
        rx_in = 1;  // bit 7
        repeat(TB_BIT_PERIOD) @(posedge clk);
        
        rx_in = 1;  // STOP bit
        repeat(TB_BIT_PERIOD) @(posedge clk);
        
        $display("UART RX reception: %s",(rx_data == 8'b1010_0011 && !frame_err) ? "PASS" : "FAIL");
        $finish;
    end
endmodule
