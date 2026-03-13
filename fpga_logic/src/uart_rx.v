`timescale 1ns / 1ps
//Tcaciuc Rares-Stefan ,12.03.2026
//wire is idle, it sits at HIGH
//to send a byte, the UART does:
//1. start bit - pulls the wire LOW for ONE tick
//2. data bits - sends 8 bits of my character ONE by ONE
//3. stop bit - pulls the wire HIGH for ONE tick

//clk of FPGA 100_000_000 times per second
//baud rate of java - 115200
//we divide them and get 868 clock cycles for one UART bit

module uart_rx(
    input clk,
    input rx_pin,
    output reg[7:0] data_out,
    output reg data_ready
    );
    
    parameter CLK_PER_BIT = 868;
    
    parameter IDLE = 2'b00;
    parameter START = 2'b01;
    parameter DATA = 2'b10;
    parameter STOP = 2'b11;
    
    reg[1:0] state = IDLE;
    reg[9:0] clock_count = 0;
    reg [2:0] bit_index = 0;
    
    
    always @(posedge clk) begin
        case (state)
            IDLE: begin 
                data_ready <= 1'b0;
                clock_count <= 0;
                bit_index <= 0;
                
                //if we detect a low signal we start reading the bit
                if(rx_pin == 1'b0) begin
                    state <= START;
                end
            end
            
            START: begin
                //wait half a bit to be able to sample in the middle
                if(clock_count == (CLK_PER_BIT/2)) begin
                    if(rx_pin == 1'b0) begin //ensure we are still reading
                        clock_count<=0;
                        state <= DATA;
                    end else begin
                        state <= IDLE;
                    end
                end else begin
                    clock_count <= clock_count+1;
                end
            end
            
            DATA: begin
                //waiting full duration
                if(clock_count < CLK_PER_BIT - 1) begin
                    clock_count <= clock_count + 1;
                end else begin
                    clock_count <= 0;
                    data_out[bit_index] <= rx_pin;
                    
                    if(bit_index<7) begin
                        bit_index <= bit_index + 1;
                    end else begin
                        bit_index <= 0;
                        state <= STOP;
                    end
                end
             end
             
             STOP: begin
                //wait 1 full bit before the stop
                if(clock_count < CLK_PER_BIT-1) begin
                    clock_count <= clock_count + 1;
                end else begin
                    //tell the top level we have a fresh letter
                    data_ready <= 1'b1;
                    clock_count <= 0;
                    state <= IDLE;
                end
             end
        endcase
     end              
endmodule
