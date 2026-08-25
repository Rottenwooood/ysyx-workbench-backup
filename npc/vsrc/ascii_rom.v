module ascii_rom(
  input clk,
  input [7:0] addr,
  output reg [7:0] data
);
  reg [7:0] mem [0:255];
  integer i;
  initial begin
    for (i = 0; i < 256; i = i + 1) mem[i] = 8'h00;
    // digits
    mem[8'h45] = 8'h30; // 0
    mem[8'h16] = 8'h31; // 1
    mem[8'h1E] = 8'h32; // 2
    mem[8'h26] = 8'h33; // 3
    mem[8'h25] = 8'h34; // 4
    mem[8'h2E] = 8'h35; // 5
    mem[8'h36] = 8'h36; // 6
    mem[8'h3D] = 8'h37; // 7
    mem[8'h3E] = 8'h38; // 8
    mem[8'h46] = 8'h39; // 9
    // letters
    mem[8'h1C] = 8'h41; // A
    mem[8'h32] = 8'h42; // B
    mem[8'h21] = 8'h43; // C
    mem[8'h23] = 8'h44; // D
    mem[8'h24] = 8'h45; // E
    mem[8'h2B] = 8'h46; // F
    mem[8'h34] = 8'h47; // G
    mem[8'h33] = 8'h48; // H
    mem[8'h43] = 8'h49; // I
    mem[8'h3B] = 8'h4A; // J
    mem[8'h42] = 8'h4B; // K
    mem[8'h4B] = 8'h4C; // L
    mem[8'h3A] = 8'h4D; // M
    mem[8'h31] = 8'h4E; // N
    mem[8'h44] = 8'h4F; // O
    mem[8'h4D] = 8'h50; // P
    mem[8'h15] = 8'h51; // Q
    mem[8'h2D] = 8'h52; // R
    mem[8'h1B] = 8'h53; // S
    mem[8'h2C] = 8'h54; // T
    mem[8'h3C] = 8'h55; // U
    mem[8'h2A] = 8'h56; // V
    mem[8'h1D] = 8'h57; // W
    mem[8'h22] = 8'h58; // X
    mem[8'h35] = 8'h59; // Y
    mem[8'h1A] = 8'h5A; // Z
  end

  always @(posedge clk) data <= mem[addr];
endmodule
