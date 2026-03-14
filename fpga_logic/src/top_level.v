`timescale 1ns / 1ps

module top_level(
    input clk,
    input dec_RsRx,
    output enc_RsTx,
    
    // Debug outputs
    output [7:0] debug_received_byte,
    output [7:0] debug_encrypted_byte,
    output [7:0] debug_fifo_out,
    output [7:0] debug_tx_byte,
    output debug_byte_ready,
    output debug_enc_ready,
    output debug_trigger_tx
);

    // =======================
    // Receiver
    // =======================
    wire [7:0] received_byte;
    wire byte_ready;

    uart_rx my_rx(
        .clk(clk),
        .rx_pin(RsRx),
        .data_out(received_byte),
        .data_ready(byte_ready)
    );

    // =======================
    // Encryptor
    // =======================
    wire [7:0] encrypted_byte;
    wire enc_ready;

    encryptor my_encryptor(
        .clk(clk),
        .data_in(received_byte),
        .data_valid(byte_ready),
        .data_out(encrypted_byte),
        .data_ready(enc_ready)
    );

    // =======================
    // FIFO
    // =======================
    wire [7:0] fifo_out_byte;
    wire fifo_empty;
    reg read_from_fifo = 0;

    fifo my_fifo(
        .clk(clk),
        .write_en(enc_ready),
        .write_data(encrypted_byte),
        .read_en(read_from_fifo),
        .read_data(fifo_out_byte),
        .empty(fifo_empty)
    );

    // =======================
    // Transmitter
    // =======================
    wire tx_is_idle;
    reg trigger_tx = 0;
    reg fifo_read_done = 0;
    reg [7:0] tx_byte_buffer = 0; // latch FIFO byte when triggering TX

    uart_tx my_tx(
        .clk(clk),
        .data_in(tx_byte_buffer),
        .send_signal(trigger_tx),
        .tx_pin(RsTx),
        .is_idle(tx_is_idle)
    );

    // =======================
    // TX Control FSM
    // =======================
always @(posedge clk) begin
    // Step 1: Request FIFO
    if (tx_is_idle && !fifo_empty && !read_from_fifo && !fifo_read_done) begin
        read_from_fifo <= 1'b1;
    end
    // Step 2: wait 1 cycle for FIFO output
    else if (read_from_fifo) begin
        read_from_fifo <= 0;
        fifo_read_done <= 1'b1;
    end
    // Step 3: latch FIFO and trigger TX
    else if (fifo_read_done && tx_is_idle) begin
        fifo_read_done <= 0;
        tx_byte_buffer <= fifo_out_byte; // latch FIFO
        trigger_tx <= 1'b1;
    end
    // Step 4: clear trigger after 1 cycle
    else if (trigger_tx) begin
        trigger_tx <= 0;
    end
end

    // =======================
    // Debug outputs
    // =======================
    assign debug_received_byte = received_byte;
    assign debug_encrypted_byte = encrypted_byte;
    assign debug_fifo_out = fifo_out_byte;
    assign debug_tx_byte = tx_byte_buffer;
    assign debug_byte_ready = byte_ready;
    assign debug_enc_ready = enc_ready;
    assign debug_trigger_tx = trigger_tx;

endmodule