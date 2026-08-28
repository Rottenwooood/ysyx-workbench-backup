module pc #(parameter WIDTH = 8,parameter ADD = 1)(
    input clk,reset,ben,
    input [WIDTH-1:0] b_addr,
    output reg [WIDTH-1:0] out
);
    always@(posedge clk) begin
        if(reset)
            out <= '0;
        else if(ben)
            out <= b_addr;
        else
            out <= out + ADD;
    end
endmodule