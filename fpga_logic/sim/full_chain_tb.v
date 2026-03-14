`timescale 1ns / 1ps

module full_chain_tb;

reg clk;
reg RsRx;

wire enc_tx;
wire dec_tx;

// debug wires
wire [7:0] enc_rx_byte;
wire [7:0] enc_byte;
wire enc_ready;
wire enc_byte_ready;

wire [7:0] dec_rx_byte;
wire [7:0] dec_byte;
wire dec_ready;


// pipeline storage
reg [7:0] last_plain;
reg [7:0] last_enc;


// =============================
// CLOCK (100 MHz)
// =============================
initial begin
    clk = 0;
    forever #5 clk = ~clk;
end


// =============================
// ENCRYPTOR
// =============================
top_level encryptor(
    .clk(clk),
    .RsRx(RsRx),
    .RsTx(enc_tx),

    .debug_received_byte(enc_rx_byte),
    .debug_encrypted_byte(enc_byte),
    .debug_byte_ready(enc_byte_ready),
    .debug_enc_ready(enc_ready)
);


// =============================
// DECRYPTOR
// =============================
decryptor_top decryptor(
    .clk(clk),
    .RsRx_enc(enc_tx),
    .RsTx_dec(dec_tx),

    .debug_rx_enc(dec_rx_byte),
    .debug_decrypted(dec_byte),
    .debug_byte_ready(dec_ready)
);


// =============================
// UART timing
// =============================
parameter BIT_PERIOD = 8680;


// =============================
// UART SEND TASK
// =============================
task send_uart_byte;
input [7:0] data;
integer i;

begin
    RsRx = 0;
    #(BIT_PERIOD);

    for(i=0;i<8;i=i+1) begin
        RsRx = data[i];
        #(BIT_PERIOD);
    end

    RsRx = 1;
    #(BIT_PERIOD);
end
endtask


// =============================
// SIMULATION SEQUENCE
// =============================
initial begin

    RsRx = 1;

    #20000;

    // seed
    send_uart_byte("S");

    // message
    send_uart_byte("S");
    send_uart_byte("A");
    send_uart_byte("L");
    send_uart_byte("u");
    send_uart_byte("t");

    #300000000;

    $finish;

end


// =============================
// PIPELINE ANALYZER
// =============================
always @(posedge clk) begin

    // store plaintext byte
    if(enc_byte_ready)
        last_plain <= enc_rx_byte;

    // store encrypted byte
    if(enc_ready)
        last_enc <= enc_byte;

    // when decryptor finishes, print full pipeline
    if(dec_ready)
        $display("PIPELINE: %c (%h) -> %h -> %c (%h)",
                 last_plain, last_plain,
                 last_enc,
                 dec_byte, dec_byte);

end

endmodule