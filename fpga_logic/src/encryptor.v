`timescale 1ns / 1ps
module encryptor(
    input clk,
    input [7:0] data_in,
    input data_valid,
    output reg [7:0] data_out,
    output reg data_ready
);

    reg [7:0] lfsr = 8'h00;
    reg seeded = 0;

    wire feedback;

    assign feedback = lfsr[7] ^ lfsr[5] ^ lfsr[4] ^ lfsr[3];

always @(posedge clk) begin
    data_ready <= 0;
    if (data_valid) begin
        if (!seeded) begin
            lfsr <= data_in;
            seeded <= 1;
        end else begin
            data_out <= data_in ^ lfsr;        // XOR first
            lfsr <= {lfsr[6:0], feedback};     // shift LFSR
            data_ready <= 1;
        end
    end
end

endmodule