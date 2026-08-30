`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: Greec Daher
// Project Name: UART 
//////////////////////////////////////////////////////////////////////////////////


module tb_uart_rx;
    
    reg clk;
    reg reset; //active-high synchronous reset
    wire rx_tick; //comes from the output of the baud_gen
    wire tx_tick; //one-bit timing tick from the baud generator
    reg rx_in; //input bit coming in from another device's TX
    wire[7:0] rx_data;
    wire frame_err;
    wire rx_busy;
    
    //GIVEN VARIABLES
    localparam TB_CLK_FREQUENCY = 100_000_000;
    localparam TB_BAUD_RATE = 115200;
        
    //CALCULATED VARIABLES   
    localparam TB_CLK_PERIOD = 1_000_000_000 / TB_CLK_FREQUENCY; //the clk to be generated
    
    //Variables used to check tests success 
    reg test1, test2, test3, test4, test5; //normal 8-bit receiving, resetting mid-receiving, invalid START bit, invalid STOP bit, back-to-back receiving (0 for failure, 1 for success)
    reg[15:0] expected_output_long; //the data expected to be recorded in rx_data from rx_in for tests requiring 16 bits
    reg[15:0] actual_output_long; //the data that was actually recorded in rx_data from rx_in for tests requiring 16 bits
    reg[7:0] expected_output; //the data expected to be recorded in rx_data from rx_in for most tests requiring 8 bits
    reg[7:0] actual_output; //the data that was actually recorded in rx_data from rx_in for most tests requiring 8 bits
    
    //Instantiate the baud_gen to provide the tx_tick
     uart_baud_gen #(
         .CLK_FREQUENCY(TB_CLK_FREQUENCY),
         .BAUD_RATE(TB_BAUD_RATE)
     ) baud_gen (
         .clk(clk),
         .reset(reset),
         .rx_tick(rx_tick),
         .tx_tick(tx_tick)
     );
     
     //Instantiate the UUT (unit-under test)
     uart_rx uut(
        .clk(clk),
        .reset(reset), //active-high synchronous reset
        .rx_tick(rx_tick), //comes from the output of the baud_gen
        .rx_in(rx_in),
        .rx_data(rx_data),
        .frame_err(frame_err),
        .rx_busy(rx_busy)
     );
     
     task wait_rx_ticks(input integer n); // wait for a number of 16x sampling ticks
        repeat(n) @(posedge rx_tick);   
    endtask
    
    task wait_bits(input integer n); // wait for a number of UART bit periods
        repeat(n) @(posedge tx_tick);   
    endtask
    
    //Generate a system clock based on the TB_CLK_PERIOD
     initial begin
         clk = 0;
         forever #(TB_CLK_PERIOD/2) clk = ~clk;
     end
     
     initial begin
        test1 = 0; test2 = 0; test3 = 0; test4 = 0; test5 = 0;
        rx_in = 1;
        actual_output = 0; actual_output_long = 0;
        expected_output  = 0; expected_output_long = 0;
        
        reset = 1;
        #60 reset = 0;    
        
        //Testing receiving normal 8-bit stream LSB first (8'b1010_0011)
        expected_output[7:0] = 8'b1010_0011; //expected output for most tests
        rx_in = 0; //START bit
        wait_bits(1);
        rx_in = 1;
        wait_bits(2);
        rx_in = 0;
        wait_bits(3);
        rx_in = 1;
        wait_bits(1);
        rx_in = 0;
        wait_bits(1);
        rx_in = 1;
        wait_bits(1);
        rx_in = 1; //STOP bit
        wait_bits(1);
        actual_output[7:0] = rx_data[7:0];
        test1 = (actual_output == expected_output) && !frame_err;
        wait_bits(5);
        
        //Testing resetting mid-receiving
        rx_in = 0; //START bit
        wait_bits(1);
        rx_in = 1;
        wait_bits(2);
        rx_in = 0;
        wait_rx_ticks(8); //sample a value mid-bit
        reset = 1; //resetting
        @(posedge clk);//waiting for the synchronous reset to take effect fully
        #1;
        test2 = (!rx_busy && rx_data == 8'h00 && !frame_err);
        rx_in = 1;
        reset = 0;
       wait_bits(5);
        
        //Testing invalid START bit
        rx_in = 0; //START bit starts
        wait_rx_ticks(4); //at the quarted of the bit, the value goes to HIGH
        rx_in = 1;
        wait_bits(1);
        rx_in = 0; //new START bit (we should check if the new received stream starts from here)
        wait_bits(1);
        rx_in = 1;
        wait_bits(2);
        rx_in = 0;
        wait_bits(3);
        rx_in = 1;
        wait_bits(1);
        rx_in = 0;
        wait_bits(1);
        rx_in = 1;
        wait_bits(1);
        rx_in = 1; //STOP bit
        wait_bits(1);
        actual_output[7:0] = rx_data[7:0];
        test3 = (actual_output == expected_output);
        wait_bits(5);
        
        //Testing invalid STOP bit
        rx_in = 0; //START bit
        wait_bits(1);
        rx_in = 1;
        wait_bits(2);
        rx_in = 0;
        wait_bits(3);
        rx_in = 1;
        wait_bits(1);
        rx_in = 0;
        wait_bits(1);
        rx_in = 1;
        wait_bits(1);
        rx_in = 0; //invalid STOP bit, frame_err should go HIGH
        wait_rx_ticks(8); //half the bit
        
        actual_output = rx_data;// The received data should still be the valid 8-bit stream
        wait_rx_ticks(2);//wait till frame_err gets asserted
        test4 = (actual_output == expected_output) && frame_err;
        wait_bits(1);
        rx_in = 1; //rx idles again at HIGH
        wait_bits(5);
        
        //Testing back-to-back receiving
        expected_output_long[15:0] = 16'b1010_0011_1010_0011; //expected output for last test
        rx_in = 0; //START bit for stream 1
        wait_bits(1);
        rx_in = 1;
        wait_bits(2);
        rx_in = 0;
        wait_bits(3);
        rx_in = 1;
        wait_bits(1);
        rx_in = 0;
        wait_bits(1);
        rx_in = 1;
        wait_bits(1);
        rx_in = 1; // STOP bit for stream 1
        wait_bits(1);
        actual_output_long[7:0] = rx_data[7:0];
        
        rx_in = 0; // START bit for stream 2
        wait_bits(1);
        rx_in = 1;
        wait_bits(2);
        rx_in = 0;
        wait_bits(3);
        rx_in = 1;
        wait_bits(1);
        rx_in = 0;
        wait_bits(1);
        rx_in = 1;
        wait_bits(1);
        rx_in = 1; //STOP bit for stream 2
        actual_output_long[15:8] = rx_data[7:0];
        test5 = (actual_output_long == expected_output_long);
        wait_bits(5);

        $display("Test 1: Result: %s", test1 ? "PASS" : "FAIL");
        $display("Test 2: Result: %s", test2 ? "PASS" : "FAIL");
        $display("Test 3: Result: %s", test3 ? "PASS" : "FAIL");
        $display("Test 4: Result: %s", test4 ? "PASS" : "FAIL");
        $display("Test 5: Result: %s", test5 ? "PASS" : "FAIL");
        $display("Tests passed: %0d/5", ({3'h0,test1} + {3'h0,test2} + {3'h0,test3} + {3'h0,test4} + {3'h0,test5}));
        
        $finish;
     end
endmodule