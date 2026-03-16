`timescale 1ns / 1ps
module decryptor_top(
    input clk,
    input RsRx_enc,          // encrypted UART input
    output RsTx_dec,         // decrypted UART output
    
    // Debug outputs
    output [7:0] debug_rx_enc,
    output [7:0] debug_decrypted,
    output [7:0] debug_tx_byte,
    output debug_byte_ready,
    output debug_trigger_tx
);

    // =======================
    // Receiver for encrypted bytes
    // =======================
    wire [7:0] rx_enc_byte;
    wire rx_enc_ready;

    uart_rx rx_enc_inst(
        .clk(clk),
        .rx_pin(RsRx_enc),
        .data_out(rx_enc_byte),
        .data_ready(rx_enc_ready)
    );

    // =======================
    // Decryptor with hardcoded key
    // =======================
    wire [7:0] dec_byte;
    wire dec_ready;

    decryptor #(
        .KEY(8'h53)  // example hardcoded key
    ) my_decryptor(
        .clk(clk),
        .data_in(rx_enc_byte),
        .data_valid(rx_enc_ready),
        .data_out(dec_byte),
        .data_ready(dec_ready)
    );

    // =======================
    // FIFO for TX
    // =======================
    wire [7:0] fifo_out;
    wire fifo_empty;
    reg fifo_read = 0;

    fifo tx_fifo(
        .clk(clk),
        .write_en(dec_ready),
        .write_data(dec_byte),
        .read_en(fifo_read),
        .read_data(fifo_out),
        .empty(fifo_empty)
    );

    // =======================
    // UART transmitter
    // =======================
    reg trigger_tx = 0;
    reg fifo_read_done = 0;
    reg [7:0] tx_byte_buf = 0;

    wire tx_idle;
    uart_tx tx_inst(
        .clk(clk),
        .data_in(tx_byte_buf),
        .send_signal(trigger_tx),
        .tx_pin(RsTx_dec),
        .is_idle(tx_idle)
    );

    // =======================
    // TX control FSM
    // =======================
    always @(posedge clk) begin
        // Step 1: request FIFO
        if(tx_idle && !fifo_empty && !fifo_read && !fifo_read_done) begin
            fifo_read <= 1'b1;
        end
        // Step 2: latch FIFO output
        else if(fifo_read) begin
            fifo_read <= 0;
            tx_byte_buf <= fifo_out;
            fifo_read_done <= 1'b1;
        end
        // Step 3: trigger TX
        else if(fifo_read_done && tx_idle) begin
            fifo_read_done <= 0;
            trigger_tx <= 1'b1;
        end
        // Step 4: clear trigger
        else if(trigger_tx) begin
            trigger_tx <= 0;
        end
    end

    // =======================
    // Debug outputs
    // =======================
    assign debug_rx_enc      = rx_enc_byte;
    assign debug_decrypted   = dec_byte;
    assign debug_tx_byte     = tx_byte_buf;
    assign debug_byte_ready  = dec_ready;
    assign debug_trigger_tx  = trigger_tx;

endmodule