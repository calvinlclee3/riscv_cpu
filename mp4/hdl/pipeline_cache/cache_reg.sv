module cache_reg 
import rv32i_types::*;
(
    input logic clk,
    input logic rst,
    input logic load,
    input cache_pipeline_reg in,
    output cache_pipeline_reg out
);

cache_pipeline_reg data;

always_ff @ (posedge clk) begin
    if (rst) begin
        data <= '0;
    end

    else if (load) begin
        data <= in;
    end
end

always_comb begin

    out = data;

end

endmodule: cache_reg