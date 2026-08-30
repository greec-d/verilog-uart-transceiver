`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: Greec Daher
// Project Name: UART 
//////////////////////////////////////////////////////////////////////////////////


module uart_tx(
    input clk,
    input reset, //active-high synchronous reset
    input tx_tick, //comes from the output of the baud_gen
    input tx_start,
    input[7:0] tx_data,
    output reg tx_out,
    output tx_busy
    );
    
    reg[2:0] bits_counter;
    reg[7:0] stored_data; 
    
    parameter IDLE=2'b00, START=2'b01, SENDING=2'b10, STOP=2'b11;
    reg[1:0] state, next_state;
    
    assign tx_busy = (state != IDLE);
    
    always@(*) begin
        case(state)
            IDLE: next_state = (tx_start)?START:IDLE;
            START: next_state = (tx_tick)?SENDING:START;
            SENDING: next_state = (tx_tick && bits_counter==7)?STOP:SENDING; 
            STOP: next_state =  (tx_tick)?IDLE:STOP;
            default: next_state = state;
        endcase
    end
    
    always@(posedge clk) begin
        if(reset) begin
            tx_out <= 1;
            state <= IDLE; 
            bits_counter <= 3'h0;
            stored_data <= 8'h0;
        end
        else begin
            state <= next_state;
            case(state)
                IDLE: begin tx_out <= 1;
                      if(tx_start) stored_data[7:0] <= tx_data[7:0]; end
                START: begin tx_out <= 0;
                       bits_counter <= 0; end 
                SENDING: begin 
                         if(tx_tick && bits_counter < 7)
                            bits_counter <= bits_counter + 3'h1;
                            
                        tx_out <= stored_data[bits_counter]; 
                        end 
                STOP: tx_out <= 1;
                default: tx_out <= tx_out;
            endcase
        end
    end
endmodule
