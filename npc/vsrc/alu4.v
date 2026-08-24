module alu4(
    input [3:0] A,
    input [3:0] B,
    input [2:0] flag,
    output carry,
    output zero,
    output overflow,
    output [3:0] result
);
    MuxKeyWithDefault #(8, 3, 5) i0 ({carry,result}, flag, 5'b0, {
        3'b000, {1'b0,A} + {1'b0,B},
        3'b001, {1'b0,A} - {1'b0,B},
        3'b010, {1'b0,4'b1111^A},
        3'b011, {1'b0,A&B},
        3'b100, {1'b0,A|B},
        3'b101, {1'b0,A^B},
        3'b110, {1'b0,{4{A < B}}},
        3'b111, {1'b0,{4'(A == B)}}
    });
    assign zero = ~(| result);
    MuxKeyWithDefault #(2, 3, 1) i1 (overflow, flag, 1'b0, {
        3'b000, (A[3] == B[3]) && (result[3] != A[3]),
        3'b001, (A[3] == B[3]) && (result[3] != A[3])
    });
endmodule