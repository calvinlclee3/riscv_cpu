module l2_cache #(
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

logic 	 hit_way1;
logic 	 hit_way0;


logic	 lru;
logic	 dirty1;
logic	 dirty0;
logic 	 load_mem_address_reg;
logic 	 read_way0_tag;
logic 	 read_way1_tag;
logic 	 read_way0_valid;
logic 	 read_way1_valid;
logic 	 read_way0_dirty;
logic 	 read_way1_dirty;
logic 	 read_lru;
logic 	 lru_mux;
logic 	 load_lru;
logic 	 read_way1_data;
logic 	 read_way0_data;
logic [1:0] data_array0_mux;
logic 	 datain0_mux;
logic 	 dirty_mux;
logic 	 load_way0_dirty;
logic 	 load_way1_dirty;
logic [1:0] data_array1_mux;
logic 	 datain1_mux;
logic 	 valid_mux;
logic 	 load_pmem_reg;
logic 	 load_way1_tag;
logic 	 load_way0_tag;
logic 	 load_way1_valid;
logic 	 load_way0_valid;
logic 	 pmem_control;

logic [31:0] mem_byte_enable256, address;

assign mem_byte_enable256 = '1;

l2_cache_control control
(.*);

l2_cache_datapath datapath
(.*);

endmodule : l2_cache
