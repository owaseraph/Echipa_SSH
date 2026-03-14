`timescale 1ns / 1ps
module top_level_tb;

reg clk;
reg RsRx;
wire RsTx;
wire [7:0] dbg_rx;
wire [7:0] dbg_enc;
wire [7:0] dbg_fifo;
wire [7:0] dbg_tx;
wire dbg_byte_ready;
wire dbg_enc_ready;
wire dbg_trigger_tx;

top_level uut(
    .clk(clk),
    .RsRx(RsRx),
    .RsTx(RsTx),
    .debug_received_byte(dbg_rx),
    .debug_encrypted_byte(dbg_enc),
    .debug_fifo_out(dbg_fifo),
    .debug_tx_byte(dbg_tx),
    .debug_byte_ready(dbg_byte_ready),
    .debug_enc_ready(dbg_enc_ready),
    .debug_trigger_tx(dbg_trigger_tx)
);

// Clock 100 MHz
initial begin
    clk = 0;
    forever #5 clk = ~clk;
end

// UART parameters
parameter BIT_PERIOD = 8680;

// UART send task
task send_uart_byte(input [7:0] data);
integer i;
begin
    RsRx = 0; #(BIT_PERIOD); // start
    for (i=0;i<8;i=i+1) begin
        RsRx = data[i]; #(BIT_PERIOD);
    end
    RsRx = 1; #(BIT_PERIOD); // stop
end
endtask

// Simulation sequence
initial begin
    RsRx = 1; // idle
    #20000;

    // Send seed/password first
    send_uart_byte("S");

    // Send message
    send_uart_byte("H");
    send_uart_byte("E");
    send_uart_byte("L");
    send_uart_byte("L");
    send_uart_byte("O");

    #50000000;
    $finish;
end

// Debug monitor
always @(posedge clk) begin
    if (dbg_byte_ready) $display("RX BYTE: %c (%h)", dbg_rx, dbg_rx);
    if (dbg_enc_ready) $display("ENCRYPTED: %h", dbg_enc);
    if (dbg_trigger_tx) $display("FIFO -> TX BYTE: %c (%h)", dbg_tx, dbg_tx);
end

// UART TX monitor: reconstruct bytes
//integer sample_count = 0;
//reg sampling = 0;
//reg [7:0] tx_shift = 0;
//integer bit_cnt = 0;

//initial begin
//    sampling = 0; bit_cnt = 0; tx_shift = 0;
//end

//always @(posedge clk) begin
//    if (!sampling && RsTx == 0) begin
//        sampling = 1;
//        sample_count = BIT_PERIOD/2;
//        bit_cnt = 0;
//        tx_shift = 0;
//    end
//    if (sampling) begin
//        sample_count = sample_count - 1;
//        if (sample_count <= 0) begin
//            if (bit_cnt < 8) begin
//                tx_shift[bit_cnt] = RsTx;
//                bit_cnt = bit_cnt + 1;
//                sample_count = BIT_PERIOD;
//            end else begin
//                sampling = 0;
//                $display("TX SERIAL BYTE: %c (%h)", tx_shift, tx_shift);
//            end
//        end
//    end
//end

endmodule