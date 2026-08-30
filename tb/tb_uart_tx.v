`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: Greec Daher
// Project Name: UART 
//////////////////////////////////////////////////////////////////////////////////


module tb_uart_tx;
    
    reg clk;
    reg reset; //active-high synchronous reset
    wire tx_tick; //comes from the output of the baud_gen instantiated below
    wire rx_tick; //used to work in any part of the 16x sampled bit
    reg tx_start;
    reg[7:0] tx_data;
    wire tx_out;
    wire tx_busy;
    
    //GIVEN VARIABLES
    localparam TB_CLK_FREQUENCY = 100_000_000;
    localparam TB_BAUD_RATE = 115200;
        
    //CALCULATED VARIABLES   
    localparam TB_CLK_PERIOD = 1_000_000_000 / TB_CLK_FREQUENCY; //the clk to be generated
     
    //Variables used to check tests success 
    reg test1, test2, test3; //normal 8-bit transmission, resetting mid-transmission, changing data mid-transmission (0 for failure, 1 for success)
    reg[7:0] expected_output; //the data expected to come out of tx_out during an 8-bit period
    reg[7:0] actual_output; //the data that was outputted by tx_out during an 8-bit transmission
    integer i;
        
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
     uart_tx uut(
        .clk(clk),
        .reset(reset), //active-high synchronous reset
        .tx_data(tx_data),
        .tx_tick(tx_tick), //comes from the output of the baud_gen
        .tx_start(tx_start),
        .tx_out(tx_out),
        .tx_busy(tx_busy)
     );
     
     task wait_rx_ticks(input integer n); // wait for a number of 16x sampling ticks
        repeat(n) @(posedge rx_tick);   
     endtask
    
     task wait_bits(input integer n); //wait for a number of UART bit periods
        repeat(n) @(posedge tx_tick);   
     endtask
    
     //Generate a system clock based on the TB_CLK_PERIOD
     initial begin
         clk = 0;
         forever #(TB_CLK_PERIOD/2) clk = ~clk;
     end
     
     initial begin
        test1 = 0; test2 = 0; test3 = 0; 
        tx_start = 0;
        actual_output = 0;
        i=0;
        
        reset = 1;
        #60 reset = 0;
        
        //Testing sending a normal 8-bit stream 
        tx_data = 8'b1011_0101;
        expected_output = tx_data;
        tx_start = 1;
        
        // Wait through the START bit and move to the middle of bit 0
        wait_bits(1);
        wait_rx_ticks(8);
        
        tx_start = 0;
        
        for(i = 0; i < 8; i=i+1) begin //loops through the results and stores them for checking values later
            actual_output[i] = tx_out;
            wait_bits(1);
            wait_rx_ticks(8); //sample in the middle of the bit
        end
        test1 = (actual_output == expected_output);
        wait_bits(5);
        
        
        //Testing reset mid-transmission (tx_out should become a constant 1)
        tx_data = 8'b1010_0011;
        tx_start = 1;
        wait_bits(1);
        tx_start = 0;
        wait_rx_ticks(48); //wait 3 bits
        reset = 1;
        @(posedge clk);
        #1;
        test2=(tx_out && !tx_busy);
        
        for(i = 0; i < 8; i=i+1) begin  //Verify reset state remains stable for several clock cycles
            if(test2 && tx_out && !tx_busy)
                test2=1;
             else
                test2=0;
             @(posedge clk);
        end
        reset = 0;
        wait_bits(5);
        
        //Testing changing the data stream mid-transmission
        tx_data = 8'b1100_0100;
        expected_output = tx_data;
        tx_start = 1;
        
        wait_bits(1);
        wait_rx_ticks(8);
        
        tx_start = 0;

        for(i = 0; i < 3; i=i+1) begin //checks the output data before the data input change
            actual_output[i] = tx_out;
            wait_bits(1);
            wait_rx_ticks(8); //sample in the middle of the bit
        end
        tx_data = 8'b0001_1101;
        for(i = 3; i < 8; i=i+1) begin //checks the output data after the data input change
            actual_output[i] = tx_out;
            wait_bits(1);
            wait_rx_ticks(8); //sample in the middle of the bit
        end        
        test3 = (actual_output == expected_output);
        wait_bits(5);
        
        //DISPLAY THE RESULTS
        $display("Test 1: Result: %s", test1 ? "PASS" : "FAIL");
        $display("Test 2: Result: %s", test2 ? "PASS" : "FAIL");
        $display("Test 3: Result: %s", test3 ? "PASS" : "FAIL");
        $display("Tests passed: %0d/3", ({2'h0,test1} + {2'h0,test2} + {2'h0,test3}));
        $finish;
     end
endmodule