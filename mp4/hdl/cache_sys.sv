
module cache_sys
import rv32i_types::*;
(
	input clk,
	input rst,

	/* Physical Memory Signals */
	output logic pmem_read,
	output logic pmem_write,
	output rv32i_word pmem_address,
	output [63:0] pmem_wdata,
	input [63:0] pmem_rdata,
	input logic pmem_resp,
	

	/* CPU Memory Signals: I-Cache */
	input logic instr_read,
	input rv32i_word instr_mem_address,
	output rv32i_word instr_mem_rdata,
	output logic instr_mem_resp,


	/* CPU Memory Signals: D-Cache */
	input logic data_read,
	input logic data_write,
	input rv32i_word data_mem_address,
	input logic [3:0] data_mbe,
	input rv32i_word data_mem_wdata,
	output rv32i_word data_mem_rdata, 
	output logic data_mem_resp
);


logic i_pmem_resp;
logic [255:0] i_pmem_rdata;
logic [31:0] i_pmem_address;
logic i_pmem_read;

logic d_pmem_resp;
logic [255:0] d_pmem_rdata;
logic [31:0] d_pmem_address;
logic [255:0] d_pmem_wdata;
logic d_pmem_read;
logic d_pmem_write;

arbiteraddressmux::arbiteraddressmux_sel_t arbiter_address_MUX_sel;

logic a_pmem_resp;
logic [255:0] a_pmem_rdata;
logic [31:0] a_pmem_address;
logic [255:0] a_pmem_wdata;
logic a_pmem_read;
logic a_pmem_write;


cache i_cache (

	.clk(clk),

	/* Physical memory signals */
	.pmem_resp(i_pmem_resp),
	.pmem_rdata(i_pmem_rdata),
	.pmem_address(i_pmem_address),
	.pmem_wdata(), // output by cache, no hardwire
	.pmem_read(i_pmem_read),
	.pmem_write(), // output by cache, no hardwire

	/* CPU memory signals */
	.mem_read(instr_read),
	.mem_write(1'b0),
	.mem_byte_enable_cpu(4'b0),
	.mem_address(instr_mem_address),
	.mem_wdata_cpu(32'b0),
	.mem_resp(instr_mem_resp),
	.mem_rdata_cpu(instr_mem_rdata)

);




cache d_cache (

	.clk(clk),

	/* Physical memory signals */
	.pmem_resp(d_pmem_resp),
	.pmem_rdata(d_pmem_rdata),
	.pmem_address(d_pmem_address),
	.pmem_wdata(d_pmem_wdata),
	.pmem_read(d_pmem_read),
	.pmem_write(d_pmem_write),

	/* CPU memory signals */
	.mem_read(data_read),
	.mem_write(data_write),
	.mem_byte_enable_cpu(data_mbe),
	.mem_address(data_mem_address),
	.mem_wdata_cpu(data_mem_wdata),
	.mem_resp(data_mem_resp),
	.mem_rdata_cpu(data_mem_rdata)

);

arbiter_datapath arbiter_datapath (

	
	/* I-Cache Side Signals */
	.i_pmem_address(i_pmem_address),
	.i_pmem_rdata(i_pmem_rdata),

	/* D-Cache Side Signals */
	.d_pmem_address(d_pmem_address),
	.d_pmem_wdata(d_pmem_wdata),
	.d_pmem_rdata(d_pmem_rdata),


	/* Physical Memory Side Signals */
	.a_pmem_address(a_pmem_address),
	.a_pmem_wdata(a_pmem_wdata),
	.a_pmem_rdata(a_pmem_rdata),

	/* Control to Datapath */
	.arbiter_address_MUX_sel(arbiter_address_MUX_sel)
);

arbiter_control arbiter_control (
	.clk(clk),
	.rst(rst),
	
	/* I-Cache Side Signals */
	.i_pmem_resp(i_pmem_resp),
	.i_pmem_read(i_pmem_read),

	/* D-Cache Side Signals */
	.d_pmem_resp(d_pmem_resp),
	.d_pmem_read(d_pmem_read),
	.d_pmem_write(d_pmem_write),

	/* Memory Side Signals */
	.a_pmem_resp(a_pmem_resp),
	.a_pmem_read(a_pmem_read),
	.a_pmem_write(a_pmem_write),

	/* Control to Datapath */
	.arbiter_address_MUX_sel(arbiter_address_MUX_sel)
);


cacheline_adaptor cacheline_adaptor (
	
	.clk(clk),
	.reset_n(~rst),

	// Port to LLC (Lowest Level Cache)
	.line_i(a_pmem_wdata),
	.line_o(a_pmem_rdata),
	.address_i(a_pmem_address),
	.read_i(a_pmem_read),
	.write_i(a_pmem_write),
	.resp_o(a_pmem_resp),

	// Port to memory
	.burst_i(pmem_rdata),
	.burst_o(pmem_wdata),
	.address_o(pmem_address),
	.read_o(pmem_read),
	.write_o(pmem_write),
	.resp_i(pmem_resp)
);

endmodule : cache_sys