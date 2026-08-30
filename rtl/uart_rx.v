`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: Greec Daher
// Project Name: UART 
//////////////////////////////////////////////////////////////////////////////////


module uart_rx(
    input clk,
    input reset, //active-high synchronous reset
    input rx_tick, //comes from the output of the baud_gen
    input rx_in, //not synchronous with my clock, needs double flopping
    output reg[7:0] rx_data,
    output reg frame_err,
    output rx_busy
    );
    
    reg[2:0] bits_counter; //counts the 8 bits received
    reg[3:0] ticks_counter; //counts the ticks when recieveing using 16x sampling
    
    parameter IDLE=2'b00, START=2'b01, RECEIVING=2'b10, STOP=2'b11;
    reg[1:0] state, next_state;
    
    //registers to hold the rx_in value before it goes to my machine
    reg rx_sync1, rx_sync2; //rx_sync1 holds the rx_in for one clock cycle which it might be metastable in, rx_sync2 takes the value of rx_sync 1 after it had already stables on a set value
    
    assign rx_busy = (state!=IDLE);
    
    always@(*) begin
        case(state) 
            IDLE: next_state = (rx_sync2)?IDLE:START;
            START: begin
                if(ticks_counter == 7 && rx_sync2 && rx_tick)
                    next_state = IDLE;
                else if (ticks_counter ==15 && rx_tick)
                    next_state = RECEIVING;
                else
                    next_state = START;
            end
            RECEIVING: next_state = (bits_counter == 7 && ticks_counter == 15 && rx_tick)?STOP:RECEIVING;
            STOP: next_state = (ticks_counter == 15 && rx_tick) ? IDLE:STOP;
            default: next_state = state;
        endcase
    end
    
    always@(posedge clk) begin
        rx_sync1 <= rx_in;     // may go metastable
        rx_sync2 <= rx_sync1;  // one extra clock period to resolve
        
        if(reset) begin
            rx_sync1 <= 1;
            rx_sync2 <= 1;
            rx_data <= 0;
            ticks_counter <= 0;
            bits_counter <= 0;
            frame_err <= 0;
            state <= IDLE;
            end
        else begin
            state <= next_state;
            if(rx_tick && state!=IDLE) //when not in IDLE, a tick happens 16 times per bit
                ticks_counter <= (ticks_counter == 15)?4'h0:(ticks_counter + 4'h1);
             if(ticks_counter == 15 && state==RECEIVING && rx_tick) begin //one bit increments after each 16 ticks
                bits_counter <= (bits_counter == 7)?3'h0:(bits_counter + 3'h1); 
             end
             if(state == STOP && ticks_counter == 7 && rx_tick) //sample the middle of the STOP state to see if its a valid stop bit
                frame_err <= !rx_sync2;  
             
             if(state == RECEIVING && ticks_counter == 7 && rx_tick)
                rx_data[bits_counter] <= rx_sync2;   

            if(state == IDLE && next_state == START) begin
                ticks_counter <= 0;
                bits_counter <= 0;
                frame_err <= 0;
             end
        end
    end
    
endmodule
