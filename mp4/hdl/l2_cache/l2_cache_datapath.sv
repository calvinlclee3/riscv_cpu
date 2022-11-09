/* MODIFY. The cache datapath. It contains the data,
valid, dirty, tag, and LRU arrays, comparators, muxes,
logic gates and other supporting logic. */

module l2_cache_datapath #(
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
		      output logic 	 hit_way1,
		      output logic 	 hit_way0,
			  output logic	 lru,
			  output logic	 dirty1,
			  output logic	 dirty0,
		      input logic 	 load_mem_address_reg,
		      input logic 	 read_way0_tag,
		      input logic 	 read_way1_tag,
		      input logic 	 read_way0_valid,
		      input logic 	 read_way1_valid,
		      input logic 	 read_way0_dirty,
		      input logic 	 read_way1_dirty,
		      input logic 	 read_lru,
		      input logic 	 lru_mux,
		      input logic 	 load_lru,
		      input logic 	 read_way1_data,
		      input logic 	 read_way0_data,
		      input logic [1:0] data_array0_mux,
		      input logic 	 datain0_mux,
		      input logic 	 dirty_mux,
		      input logic 	 load_way0_dirty,
		      input logic 	 load_way1_dirty,
		      input logic [1:0] data_array1_mux,
		      input logic 	 datain1_mux,
		      input logic 	 valid_mux,
		      input logic 	 load_pmem_reg,
		      input logic 	 load_way1_tag,
		      input logic 	 load_way0_tag,
		      input logic 	 load_way1_valid,
		      input logic 	 load_way0_valid,
		      input logic 	 pmem_control,
              output logic [255:0] pmem_wdata, 
              output logic [31:0]  pmem_address,
              output logic [255:0] mem_rdata256, 
              input logic [31:0] mem_byte_enable256,
              input  logic [31:0]    mem_address,
              input logic [255:0]   pmem_rdata,
              input logic [255:0] mem_wdata256,
              output logic [31:0] address
);

logic [2:0] index;
logic [23:0] tag, tagway1out, tagway0out;
logic [31:0] aligned_addr;
logic [255:0] pmem_rdata_out;
logic valid_in, valid0_out, valid1_out, dirty_in, lru_in;

assign pmem_rdata_out = pmem_rdata;
assign tag = mem_address[31:8];
assign index = mem_address[7:5];
assign aligned_addr = {mem_address[31:5], 5'b0};
assign address = mem_address;

   l2_array #(3, s_tag) tag_way0(.clk, .rst, .read(1'b1), .load(load_way0_tag), .rindex(index), .windex(index), .datain(tag), .dataout(tagway0out));
l2_array #(3, s_tag) tag_way1(.clk, .rst, .read(1'b1), .load(load_way1_tag), .rindex(index), .windex(index), .datain(tag), .dataout(tagway1out));
l2_array valid_way0(.clk, .rst, .read(1'b1), .load(load_way0_valid), .rindex(index), .windex(index), .datain(valid_in), .dataout(valid0_out));
   l2_array valid_way1(.clk, .rst, .read(1'b1), .load(load_way1_valid), .rindex(index), .windex(index), .datain(valid_in), .dataout(valid1_out));
l2_array dirty_way0(.clk, .rst, .read(1'b1), .load(load_way0_dirty), .rindex(index), .windex(index), .datain(dirty_in), .dataout(dirty0));
l2_array dirty_way1(.clk, .rst, .read(1'b1), .load(load_way1_dirty), .rindex(index), .windex(index), .datain(dirty_in), .dataout(dirty1));
l2_array lru_array(.clk, .rst, .read(1'b1), .load(load_lru), .rindex(index), .windex(index), .datain(lru_in), .dataout(lru));


//tag, valid, dirty, lru muxes

//valid_mux
l2_two_one_mux valid_m (.selection(valid_mux), .A(1'b0), .B(1'b1), .dataout(valid_in));
//dirty_mux
l2_two_one_mux dirty_m (.selection(dirty_mux), .A(1'b0), .B(1'b1), .dataout(dirty_in));
//lru_mux
l2_two_one_mux lru_m (.selection(lru_mux), .A(1'b0), .B(1'b1), .dataout(lru_in));


logic [s_line-1:0] datain1_mux_out, datain0_mux_out, data0_out, data1_out;


logic [31:0] data_array0_mux_out, data_array1_mux_out;

//data1_mux
always_comb begin
    datain1_mux_out = mem_wdata256;
    case (datain1_mux)

    1'b0: datain1_mux_out = mem_wdata256; 

    1'b1: datain1_mux_out = pmem_rdata_out;

    endcase
end

always_comb begin
    datain0_mux_out = mem_wdata256;
    case (datain0_mux)

    1'b0: datain0_mux_out = mem_wdata256; 

    1'b1: datain0_mux_out = pmem_rdata_out;

    endcase
end


always_comb begin
    data_array0_mux_out = 32'h0;

    case (data_array0_mux)
    2'b00: data_array0_mux_out = 32'h0;
    2'b01: data_array0_mux_out = mem_byte_enable256;
    2'b10: data_array0_mux_out = {32{1'b1}};
    default: data_array0_mux_out = 32'h0;
    endcase
end


always_comb begin
    data_array1_mux_out = 32'h0;

    case (data_array1_mux)
    2'b00: data_array1_mux_out = 32'h0;
    2'b01: data_array1_mux_out = mem_byte_enable256;
    2'b10: data_array1_mux_out = {32{1'b1}};
    default: data_array1_mux_out = 32'h0;
    endcase
end




l2_data_array data_way0(.clk, .read(1'b1), .write_en(data_array0_mux_out), .rindex(index), .windex(index), .datain(datain0_mux_out), .dataout(data0_out));
l2_data_array data_way1(.clk, .read(1'b1), .write_en(data_array1_mux_out), .rindex(index), .windex(index), .datain(datain1_mux_out), .dataout(data1_out));

logic hit_way1_out, hit_way0_out;
assign hit_way1 = hit_way1_out;
assign hit_way0 = hit_way0_out;

always_comb begin

    mem_rdata256 = data1_out;

    case (hit_way0_out)
    1'b0: mem_rdata256 = data1_out;
    1'b1: mem_rdata256 = data0_out;
    endcase

end

always_comb begin

    pmem_wdata = data0_out;

    case (lru)
    1'b0: pmem_wdata = data0_out;
    1'b1: pmem_wdata = data1_out;
    endcase

end

logic [31:0] ptag;

always_comb begin
ptag = {tagway0out, index, 5'b0};
case (lru)
1'b0: ptag = {tagway0out, index, 5'b0};
1'b1: ptag = {tagway1out, index, 5'b0};
endcase

end



always_comb begin

    pmem_address = aligned_addr;

    case (pmem_control)
    1'b0: pmem_address = aligned_addr;
    1'b1: pmem_address = ptag;
    endcase

end

logic comparator1_out, comparator0_out;

always_comb begin

comparator1_out = (tag == tagway1out)? 1'b1: 1'b0;
comparator0_out = (tag == tagway0out)? 1'b1: 1'b0;


hit_way0_out = comparator0_out & valid0_out;
hit_way1_out = comparator1_out & valid1_out;

end


endmodule : l2_cache_datapath
