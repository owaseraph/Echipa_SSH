`timescale 1ns / 1ps
//Tcaciuc Rares-Stefan, 13.03.2026
//creating a fifo buffer to remove the race condition we encountered after the first version of the transmission


module fifo(
    input clk, //internal clock
    input write_en, //rx singal data_ready
    input [7:0] write_data, //modified byte from rx
    input read_en, //tx signal for idle
    output reg[7:0] read_data, //the byte we send to tx
    output empty //goes HIGH when the fifo module is empty
    );
    
    //the "waiting room" - array of 16 memories registers, each 8 bits wide
    reg[7:0] memory [0:15];
    
    
    //pointers
    reg[3:0] write_ptr; //points to the next empty space (0,15)
    reg[3:0] read_ptr; //points to the oldest occupied space (0,15)
    reg [4:0] count = 0; //how many spaces are in the "room"
    
    assign empty = (count == 0);
    
    always @(posedge clk) begin
        //1. writing
        if(write_en == 1'b1 && count < 16) begin
            memory[write_ptr] <= write_data;
            write_ptr = write_ptr + 1;
        end
        
        
        //2. reading
        if(read_en == 1'b1 && count > 0) begin
            read_data <= memory[read_ptr];
            read_ptr <= read_ptr+1;
        end
        
        //3. keeping count
        if(write_en && !read_en && count<16) begin
            count <= count + 1;
        end else if(!write_en && read_en && count > 0) begin
            count <= count - 1;
        end
     end
endmodule
