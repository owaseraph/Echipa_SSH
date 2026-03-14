`timescale 1ns / 1ps
module fifo(
    input clk,
    input write_en,
    input [7:0] write_data,
    input read_en,
    output reg [7:0] read_data,
    output empty
);

    reg [7:0] memory [0:15];
    reg [3:0] write_ptr = 0;
    reg [3:0] read_ptr = 0;
    reg [4:0] count = 0;

    assign empty = (count == 0);

    always @(posedge clk) begin
        // Write
        if (write_en && count < 16) begin
            memory[write_ptr] <= write_data;
            write_ptr <= write_ptr + 1;
        end

        // Read (data valid next cycle)
        if (read_en && count > 0) begin
            read_data <= memory[read_ptr];
            read_ptr <= read_ptr + 1;
        end

        // Count logic
        if (write_en && !read_en && count < 16) count <= count + 1;
        else if (!write_en && read_en && count > 0) count <= count - 1;
    end
endmodule