module shift_reg #(WIDTH = 8, parameter [WIDTH-1:0] RESET_VAL = 0)(
    input x,
    input clk,
    input [2:0] mode,
    output reg [WIDTH-1:0] y
);
    always@(posedge clk) begin
        case(mode)
            3'b000: y <= {WIDTH{1'b0}};
            3'b001: y <= RESET_VAL;
            3'b010: y <= {1'b0,y[WIDTH-1:1]};
            3'b011: y <= {y[WIDTH-2:0],1'b0};
            3'b100: y <= {y[WIDTH-1],y[WIDTH-1:1]};
            3'b101: y <= {x,y[WIDTH-1:1]};
            3'b110: y <= {y[0],y[WIDTH-1:1]};
            3'b111: y <= {y[WIDTH-2:0],y[WIDTH-1]};
            default: y <= RESET_VAL;
        endcase
    end
endmodule