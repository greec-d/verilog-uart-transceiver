    `timescale 1ns / 1ps
    //////////////////////////////////////////////////////////////////////////////////
    // Engineer: Greec Daher
    // Project Name: UART 
    //////////////////////////////////////////////////////////////////////////////////
    
    
    module tb_baud_gen;
        
        reg clk;
        reg reset; //active-high synchronous reset
        wire rx_tick;
        wire tx_tick;
        
        //GIVEN VARIABLES
        localparam TB_CLK_FREQUENCY = 100_000_000;
        localparam TB_BAUD_RATE = 115200;
        
        //CALCULATED VARIABLES   
        localparam TB_CLK_PER_BIT = TB_CLK_FREQUENCY/TB_BAUD_RATE; //how many clock cycles per one bit 
        localparam TB_CLK_PERIOD = 1_000_000_000 / TB_CLK_FREQUENCY; //the clk to be generated
        
        //TESTING VARIABLES
        localparam TB_RX_INTERVAL = (TB_CLK_PER_BIT / 16) * TB_CLK_PERIOD; //the expected interval between each two rx ticks
        localparam TB_TX_INTERVAL = TB_RX_INTERVAL * 16; //the expected interval between each two tx ticks
        
        //Variables used to test the rx_ticks
        time last_rx_tick;
        integer rx_failures, rx_success;
        
        //Variables used to test the tx_ticks
        time last_tx_tick;
        integer tx_failures, tx_success;
        
        //Generate a system clock based on the TB_CLK_PERIOD
        initial begin
            clk = 0;
           forever #(TB_CLK_PERIOD/2) clk = ~clk;
        end
        
        // Instantiate the unit under test (UUT)
        uart_baud_gen #(
            .CLK_FREQUENCY(TB_CLK_FREQUENCY),
            .BAUD_RATE(TB_BAUD_RATE)
        ) uut (
            .clk(clk),
            .reset(reset),
            .rx_tick(rx_tick),
            .tx_tick(tx_tick)
        );
        
        initial begin
            rx_failures = 0; rx_success = 0; last_rx_tick = 0;
            tx_failures = 0; tx_success = 0; last_tx_tick = 0;
            //Apply the synchronous reset then wait long enough to see sufficient outputs behaviour
            reset = 1;
            #60 reset = 0;
            #30000;
            $display("========================================");
            $display("UART BAUD GENERATOR TEST");
            $display("========================================");
            $display("RX intervals checked: %0d", (rx_success + rx_failures));
            $display("RX intervals Succeeded/Failed: %0d/%0d", rx_success, rx_failures);
            $display("TX intervals checked: %0d", (tx_success + tx_failures));
            $display("TX intervals Succeeded/Failed: %0d/%0d", tx_success, tx_failures);
            $display();
            $display("Result: %s",((rx_failures+tx_failures==0) && (rx_success>0) && (tx_success>0))?"PASS":"FAILED");  
            $finish;
        end
        
        //check if the RX ticks are correctly seperated, display the results in the initial block
        always@(posedge rx_tick) begin
            if(last_rx_tick != 0) begin       
                if(($time-last_rx_tick) == TB_RX_INTERVAL) 
                    rx_success = rx_success + 1;
                 else
                    rx_failures = rx_failures + 1;
            end
            last_rx_tick = $time;
        end
        
        //check if the TX ticks are correctly seperated, display the results in the initial block
        always@(posedge tx_tick) begin
            if(last_tx_tick != 0) begin
                if(($time-last_tx_tick) == TB_TX_INTERVAL) 
                    tx_success = tx_success + 1;
                 else
                    tx_failures = tx_failures + 1;
            end
            last_tx_tick = $time;
        end
    endmodule
