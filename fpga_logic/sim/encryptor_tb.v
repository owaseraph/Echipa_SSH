`timescale 1ns / 1ps

module encryptor_tb;

    //inputs
    reg clk;
    reg [7:0] data_in;
    reg data_valid;

    //outputs
    wire [7:0] data_out;
    wire data_ready;

    //instantiate encryptor
    encryptor uut (
        .clk(clk),
        .data_in(data_in),
        .data_valid(data_valid),
        .data_out(data_out),
        .data_ready(data_ready)
    );

    //clock generation (100MHz -> 10ns period)
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    //task to send a byte
    task send_byte;
        input [7:0] byte;
        begin
            @(posedge clk);
            data_in = byte;
            data_valid = 1;

            @(posedge clk);
            data_valid = 0;
        end
    endtask


    //stimulus
    initial begin

        data_in = 0;
        data_valid = 0;

        //wait a bit
        #20;

        //send password (seed)
        send_byte("S");

        //send message
        send_byte("H");
        send_byte("E");
        send_byte("L");
        send_byte("L");
        send_byte("O");

        //wait to see results
        #200;

        $finish;
    end


    //monitor output
always @(posedge clk) begin
    if (data_ready) begin
        $display("TIME=%0t | INPUT='%c' (0x%h) | KEY=0x%h | OUTPUT=0x%h | OUT_CHAR='%c'",
                  $time,
                  data_in,
                  data_in,
                  uut.lfsr,
                  data_out,
                  data_out);
    end
end

endmodule