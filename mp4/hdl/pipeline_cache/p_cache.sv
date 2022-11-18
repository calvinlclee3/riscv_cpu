module p_cache (
  input clk,

  /* Physical memory signals */
  input logic pmem_resp,
  input logic [255:0] pmem_rdata,
  output logic [31:0] pmem_address,
  output logic [255:0] pmem_wdata,
  output logic pmem_read,
  output logic pmem_write,

  /* CPU memory signals */
  input logic mem_read,
  input logic mem_write,
  input logic [3:0] mem_byte_enable_cpu,
  input logic [31:0] mem_address,
  input logic [31:0] mem_wdata_cpu,
  output logic mem_resp,
  output logic [31:0] mem_rdata_cpu
);

logic tag_load;
logic valid_load;
logic dirty_load;
logic dirty_in;
logic dirty_out;

logic hit;
logic [1:0] writing;

logic [255:0] mem_wdata;
logic [255:0] mem_rdata;
logic [31:0] mem_byte_enable;

logic [31:0] read_address;

cache_pipeline_reg cache_pipeline_reg_in;
cache_pipeline_reg cache_pipeline_reg_out;

cache_control control(.*);
cache_datapath datapath(.*);

always_comb begin
  read_address = 32'h0000;

  case(address_mux_sel)
    1'b0: read_address = mem_address;
    1'b1: read_address = cache_pipeline_reg_out.cpu_address;
	endcase
end
p_line_adapter bus (
    .mem_wdata_line(mem_wdata),
    .mem_rdata_line(mem_rdata),
    .mem_wdata(mem_wdata_cpu),
    .mem_rdata(mem_rdata_cpu),
    .mem_byte_enable(mem_byte_enable_cpu),
    .mem_byte_enable_line(mem_byte_enable),
    .address(mem_address)
);

endmodule : p_cache
