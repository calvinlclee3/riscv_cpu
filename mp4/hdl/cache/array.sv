module array #(parameter width = 1)
(
  input clk,
  input rst,
  input logic load,
  input logic [3:0] rindex,
  input logic [3:0] windex,
  input logic [width-1:0] datain,
  output logic [width-1:0] dataout
);

logic [width-1:0] data [16];

always_comb begin
  dataout = (load  & (rindex == windex)) ? datain : data[rindex];
end

always_ff @(posedge clk)
begin
    if(rst)
    begin
      for (int i = 0; i < 16; ++i)
        data[i] <= '0;
    end
    else if(load)
        data[windex] <= datain;
end

endmodule : array
