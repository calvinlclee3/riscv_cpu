/* MODIFY. Your cache design. It contains the cache
controller, cache datapath, and bus adapter. */

module l2_cache 
import rv32i_types::*;
import cache_mux_types::*;
#(
    parameter s_offset = 5,
    parameter s_index  = 3,
    parameter s_tag    = 32 - s_offset - s_index,
    parameter s_mask   = 2**s_offset,
    parameter s_line   = 8*s_mask,
    parameter num_sets = 2**s_index
)
(
    input clk,
    input rst,

    /* CPU memory signals */
    input   logic [31:0]    mem_address,
    output  logic [255:0]   mem_rdata256,
    input   logic [255:0]   mem_wdata256,
    input   logic           mem_read,
    input   logic           mem_write,
    output  logic           mem_resp,

    /* Physical memory signals */
    output  logic [31:0]    pmem_address,
    input   logic [255:0]   pmem_rdata,
    output  logic [255:0]   pmem_wdata,
    output  logic           pmem_read,
    output  logic           pmem_write,
    input   logic           pmem_resp
);

logic [31:0]  mem_byte_enable256;
assign mem_byte_enable256 = 32'b1;

/* Datapath to Control */
logic hit;
logic way_0_hit;
logic way_1_hit;

logic v_array_0_dataout;
logic v_array_1_dataout;

logic d_array_0_dataout;
logic d_array_1_dataout;

logic LRU_array_dataout;

/* Control to Datapath */
logic v_array_0_load;
logic v_array_0_datain;
logic v_array_1_load;
logic v_array_1_datain;

logic d_array_0_load;
logic d_array_0_datain;
logic d_array_1_load;
logic d_array_1_datain;

logic tag_array_0_load;
logic tag_array_1_load;

logic LRU_array_load;
logic LRU_array_datain;

logic memory_buffer_register_load;

dataarraymux_sel_t write_en_0_MUX_sel;
dataarraymux_sel_t write_en_1_MUX_sel;
dataarraymux_sel_t data_array_0_datain_MUX_sel;
dataarraymux_sel_t data_array_1_datain_MUX_sel;

logic dataout_MUX_sel;

pmemaddressmux_sel_t pmem_address_MUX_sel;





l2_cache_control control (.*);

l2_cache_datapath datapath (.*);


endmodule : l2_cache
