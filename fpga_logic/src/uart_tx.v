`timescale 1ns / 1ps
//Tcaciuc Rares-Stefan, 11.03.2026
//we wait for the signal, load the 8 bits, shift them to the tx_pin one by one, waiting 868 clock cycles between each shift


module uart_tx(
    input clk, //FPGA clock
    input [7:0] data_in, //8bit letter to be modified
    input send_signal, //trigger impulse to start sending
    output reg tx_pin, //the physical wire going to the USB
    output is_idle //tells the top level it is ready for transmitting
    );
    
    parameter CLK_PER_BIT = 868;
     
    parameter IDLE = 2'b00;
    parameter START = 2'b01;
    parameter DATA = 2'b10;
    parameter STOP = 2'b11;
    
    reg[1:0] state = IDLE;
    reg[9:0] clock_count = 0; //counts up to 868
    reg [2:0] bit_index = 0; //counts from 0 to 7 for the 8 bits
    reg [7:0] saved_data = 0; //holds our letter so it doesnt change while serial communicates
    
    initial tx_pin = 1'b1;
    assign is_idle = (state==IDLE);
    
    always @(posedge clk) begin
        case(state)
            IDLE: begin
                tx_pin <= 1'b1; // keep wire HIGH
                clock_count <= 0;
                bit_index <= 0;
                
                if(send_signal == 1'b1) begin
                    saved_data <= data_in;
                    state <= START;
                end
            end
            
            START: begin
                tx_pin <= 1'b0; //pull wire to LOW to signal a new byte is coming
                
                //wait for 1 bit duration
                if(clock_count < CLK_PER_BIT - 1) begin
                    clock_count <= clock_count + 1;
                end else begin
                    clock_count <= 0;
                    state <= DATA;
                end
            end
            
            DATA: begin
                tx_pin <= saved_data[bit_index]; //put the current bit on the wire
                
                if(clock_count < CLK_PER_BIT - 1) begin
                    clock_count <= clock_count + 1;
                end else begin
                    clock_count <= 0;
                    //check for all 8 bits
                    
                    if(bit_index < 7) begin
                        bit_index <= bit_index + 1;
                    end else begin
                        bit_index <= 0;
                        state <= STOP; //move to stop bit
                    end
                end
            end
            
            STOP: begin
                tx_pin <= 1'b1; //pull wire HIGH to signal the end
                
                if(clock_count < CLK_PER_BIT - 1) begin
                    clock_count <= clock_count + 1;
                end else begin
                    clock_count <= 0;
                    state <= IDLE; // all is done, wait for new byte
                end
            end
        endcase
     end
endmodule
