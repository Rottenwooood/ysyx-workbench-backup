module pc #(parameter WIDTH = 8,parameter ADD = 1,parameter RESET_VAL = 0)(
    input clk,reset,ben,
    input [WIDTH-1:0] b_addr,
    output reg [WIDTH-1:0] out
);
    always@(posedge clk) begin
        if(reset)
            out <= RESET_VAL;
        else if(ben)
            out <= b_addr;
        else
            out <= out + ADD;
    end
endmodule