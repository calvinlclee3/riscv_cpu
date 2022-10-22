module if_id_reg 
import rv32i_types::*;
(
    input logic clk,
    input logic rst,
    input logic flush,
    input logic load,
    input if_id_pipeline_reg in,
    output if_id_pipeline_reg out
);

if_id_pipeline_reg data;


always_ff @ (posedge clk) begin
    if (rst | flush) begin
        data <= '0;
    end

    else if (load) begin
        data <= in;
    end
end

always_comb begin

    out = data;

end

endmodule: if_id_reg