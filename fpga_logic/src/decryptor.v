`timescale 1ns / 1ps
module decryptor #(
    parameter KEY = 8'h00  // hardcoded key
)(
    input clk,
    input [7:0] data_in,
    input data_valid,
    output reg [7:0] data_out,
    output reg data_ready
);

    reg [7:0] lfsr = KEY;
    wire feedback;

    assign feedback = lfsr[7] ^ lfsr[5] ^ lfsr[4] ^ lfsr[3];

    always @(posedge clk) begin
        data_ready <= 0;

        if(data_valid) begin
            // XOR decryption
            data_out <= data_in ^ lfsr;

            // advance LFSR
            lfsr <= {lfsr[6:0], feedback};

            data_ready <= 1;
        end
    end

endmodule