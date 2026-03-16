module crypto_relay(
    input clk,

    input dec_RsRx,
    output enc_RsTx,

    input RsRx_enc,
    output RsTx_dec
);

top_level encryptor(
    .clk(clk),
    .dec_RsRx(dec_RsRx),
    .enc_RsTx(enc_RsTx)
);

decryptor_top decryptor(
    .clk(clk),
    .RsRx_enc(RsRx_enc),
    .RsTx_dec(RsTx_dec)
);

endmodule