`timescale 1ns / 1ps

module decryptor_tb;

reg clk;
reg RsRx;
wire RsTx;

// debug
wire [7:0] dbg_rx_enc;
wire [7:0] dbg_decrypted;
wire [7:0] dbg_tx_byte;
wire dbg_byte_ready;
wire dbg_trigger_tx;

// Instantiate decryptor top
decryptor_top uut(
.clk(clk),
.RsRx_enc(RsRx),
.RsTx_dec(RsTx),
.debug_rx_enc(dbg_rx_enc),
.debug_decrypted(dbg_decrypted),
.debug_tx_byte(dbg_tx_byte),
.debug_byte_ready(dbg_byte_ready),
.debug_trigger_tx(dbg_trigger_tx)
);

// Clock
initial begin
clk = 0;
forever #5 clk = ~clk; // 100 MHz
end

// UART timing
parameter BIT_PERIOD = 8680;

// Send UART byte
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

initial begin

RsRx = 1;
#20000;

// send encrypted bytes
send_uart_byte(8'h1B);
send_uart_byte(8'hE2);
send_uart_byte(8'h02);
send_uart_byte(8'hD1);
send_uart_byte(8'h74);

#200000000
$finish;

end

// Debug monitor
always @(posedge clk) begin

if(dbg_byte_ready)
    $display("DECRYPTED BYTE: %c (%h)", dbg_decrypted, dbg_decrypted);

if(dbg_trigger_tx)
    $display("TX BYTE: %c (%h)", dbg_tx_byte, dbg_tx_byte);

end

endmodule