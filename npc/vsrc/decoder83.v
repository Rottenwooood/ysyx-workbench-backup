module decoder83(x,en,y,f);
  input  [7:0] x;
  input  en;
  output reg [2:0]y;
  output reg f;
  integer i;
  always @(x or en) begin
    if (en) begin
      y = 0;f = 0;
      for( i = 0; i <= 7; i = i+1)
          if(x[i] == 1)  begin
            y = i[2:0];
            f = 1;
          end
    end
    else begin y = 0; f = 0; end
  end
endmodule
