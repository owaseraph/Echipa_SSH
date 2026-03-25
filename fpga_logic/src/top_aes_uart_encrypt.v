module top_aes_uart_encrypt(
    input        clk,
    input        rst,
    input        i_rx,       // UART RX
    output       o_tx        // UART TX
);

    // ---------- 128-bit Packet Buffer ----------
    wire [127:0] plaintext_block;
    wire         block_valid;
    wire [7:0]   rx_byte;
    wire         rx_dv;

    // Use UART top for both RX and TX
    wire tx_dv;
    wire [7:0] tx_byte;
    wire tx_done;

    uart_top uart_inst (
        .i_clk(clk),
        .i_rst(rst),
        .i_rx(i_rx),
        .o_tx(o_tx),
        // TX interface
        .i_tx_dv(tx_dv),
        .i_tx_byte(tx_byte),
        .o_tx_done(tx_done),
        // RX interface
        .o_rx_dv(rx_dv),
        .o_rx_byte(rx_byte)
    );

    uart_packet_buffer packet_buf (
        .clk(clk),
        .rst(rst),
        .i_byte_dv(rx_dv),
        .i_byte(rx_byte),
        .o_block(plaintext_block),
        .o_block_valid(block_valid)
    );

    // ---------- AES Encrypt ----------
    reg aes_start = 0;
    wire [127:0] ciphertext;
    wire aes_done;

    aes128_encrypt aes (
        .clk(clk),
        .rst(rst),
        .start(aes_start),
        .plaintext(plaintext_block),
        .ciphertext(ciphertext),
        .done(aes_done)
    );

    // Pulse AES start once per block
    always @(posedge clk or posedge rst) begin
        if (rst)
            aes_start <= 0;
        else
            aes_start <= block_valid;
    end

    // Display ciphertext when AES finishes
    always @(posedge clk) begin
        if (aes_done)
            $display("AES Done! Ciphertext = %h", ciphertext);
    end

    // ---------- UART TX Buffer ----------
uart_tx_buffer tx_buf (
    .clk(clk),
    .rst(rst),
    .start(aes_done),
    .block_in(ciphertext),
    .tx_done(tx_done),   
    .tx_dv(tx_dv),
    .tx_byte(tx_byte),
    .done()
);

endmodule