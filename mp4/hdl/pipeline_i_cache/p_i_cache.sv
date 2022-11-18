module p_i_cache
import rv32i_types::*;
import cache_mux_types::*;
#(
    parameter s_offset = 5,
    parameter s_index  = 3,
    parameter s_tag    = 32 - s_offset - s_index,
    parameter s_mask   = 2**s_offset,
    parameter s_line   = 8*s_mask,
    parameter num_sets = 2**s_index,
    parameter num_ways = 4
) 
  input clk,
  input rst,
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

logic hit;

logic [255:0] mem_wdata;
logic [255:0] mem_rdata;
logic [31:0] mem_byte_enable;

logic v_array_0_dataout;
logic v_array_1_dataout;
logic v_array_2_dataout;
logic v_array_3_dataout;

logic [2:0] LRU_array_dataout;

logic v_array_0_load;
logic v_array_0_datain;
logic v_array_1_load;
logic v_array_1_datain;
logic v_array_2_load;
logic v_array_2_datain;
logic v_array_3_load;
logic v_array_3_datain;

logic tag_array_0_load;
logic tag_array_1_load;
logic tag_array_2_load;
logic tag_array_3_load;

i_cache_pipeline_reg cache_pipeline_in;
i_cache_pipeline_reg cache_pipeline_out;

p_i_cache_control control(
  .clk,
  .rst,

  /* CPU memory signals */
  .mem_read,
  .mem_resp,

  /* Physical memory signals */
  .pmem_resp,
  .pmem_read,

  /* Datapath to Control */
  .v_array_0_dataout,
  .v_array_1_dataout,
  .v_array_2_dataout,
  .v_array_3_dataout,

  .cache_pipeline_out,
  .cache_pipeline_in,

  .LRU_array_dataout,

  /* Control to Datapath */
  output logic v_array_0_load,
  output logic v_array_0_datain,
  output logic v_array_1_load,
  output logic v_array_1_datain,
  output logic v_array_2_load,
  output logic v_array_2_datain,
  output logic v_array_3_load,
  output logic v_array_3_datain,

  output logic tag_array_0_load,
  output logic tag_array_1_load,
  output logic tag_array_2_load,
  output logic tag_array_3_load,

  output logic LRU_array_load,
  output logic [2:0] LRU_array_datain,

  output dataarraymux_sel_t write_en_0_MUX_sel,
  output dataarraymux_sel_t write_en_1_MUX_sel,
  output dataarraymux_sel_t write_en_2_MUX_sel,
  output dataarraymux_sel_t write_en_3_MUX_sel,
  output dataarraymux_sel_t data_array_0_datain_MUX_sel,
  output dataarraymux_sel_t data_array_1_datain_MUX_sel,
  output dataarraymux_sel_t data_array_2_datain_MUX_sel,
  output dataarraymux_sel_t data_array_3_datain_MUX_sel,

  output paddressmux_sel_t address_mux_sel,
);


//STAGE 1: COMPARE TAG AND SEE IF HIT OR MISS







//STAGE 2: DELIVER DATA



//HARDWARE UNITS



always_comb begin : 


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







endmodule : p_i_cache
