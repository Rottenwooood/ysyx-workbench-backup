module alu #(parameter WIDTH = 8)(
    input [WIDTH-1:0] A,
    input [WIDTH-1:0] B,
    input [2:0] flag,
    output carry,
    output zero,
    output overflow,
    output [WIDTH-1:0] result
);
    MuxKeyWithDefault #(8, 3, WIDTH+1) i0 ({carry,result}, flag, {(WIDTH+1){1'b0}}, {
        3'b000, {1'b0,A} + {1'b0,B},
        3'b001, {1'b0,A} - {1'b0,B},
        3'b010, {1'b0,{WIDTH{1'b1}}^A},
        3'b011, {1'b0,A&B},
        3'b100, {1'b0,A|B},
        3'b101, {1'b0,A^B},
        3'b110, {1'b0,{WIDTH{A < B}}},
        3'b111, {1'b0,{WIDTH'(A == B)}}
    });
    assign zero = ~(| result);
    MuxKeyWithDefault #(2, 3, 1) i1 (overflow, flag, 1'b0, {
        3'b000, (A[WIDTH-1] == B[WIDTH-1]) && (result[WIDTH-1] != A[WIDTH-1]),
        3'b001, (A[WIDTH-1] == B[WIDTH-1]) && (result[WIDTH-1] != A[WIDTH-1])
    });
endmodule