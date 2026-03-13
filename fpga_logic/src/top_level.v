`timescale 1ns / 1ps

//Tcaciuc Rares-Stefan, 12.03.2026
//take a letter, add 1 to it and then send it back

//encountered a race condition, because it takes for the receiver 9.5 bit durations after it starts, it tells me that the data is ready after that
//for the transmitter, it takes 10 bit-durations
//for example HLA should be IBM
//but RX catches H, TX is starting to send I
//RX catches L,  but TX is still in the STOP bit for the letter I, so it skips this letter
//RX catches A, TX is starting to send B
// and again TX is late for the \n so it skips it


//fast fix: make TX STOP bit shorter
//future fix: FIFO buffer (First In First Out)


module top_level(
    input clk,
    input RsRx,
    output RsTx
    );
    
    //receiver
    wire [7:0] received_byte;
    wire byte_ready;
    
    uart_rx my_rx(
        .clk(clk),
        .rx_pin(RsRx),
        .data_out(received_byte),
        .data_ready(byte_ready)
    );
    
    //modifier
    
    wire [7:0] modified_byte = received_byte+1;
    
    
    //fifo
    wire [7:0] fifo_out_byte;
    wire fifo_empty;
    reg read_from_fifo = 0;
    
    fifo my_fifo(
        .clk(clk),
        .write_en(byte_ready),
        .write_data(modified_byte),
        .read_en(read_from_fifo),
        .read_data(fifo_out_byte),
        .empty(fifo_empty)
    );
    
    //transmitter
    wire tx_is_idle;
    reg trigger_tx = 0;
    uart_tx my_tx(
        .clk(clk),
        .data_in(modified_byte),
        .send_signal(byte_ready),
        .tx_pin(RsTx),
        .is_idle(tx_is_idle)
    );
    
    always @(posedge clk) begin
        //if tx is idle
        if (tx_is_idle && !fifo_empty && !read_from_fifo && !trigger_tx) begin
            read_from_fifo <= 1'b1; //tell FIFO to give us a letter
        
        end else if (read_from_fifo) begin
            read_from_fifo <= 1'b0; 
            trigger_tx <= 1'b1;     //letter is in buffer, tell tx to transmit
        
        end else if (trigger_tx) begin
            trigger_tx <= 1'b0;     //turn off tx so it doesnt send twice
        end
    end

endmodule 
