
module mp4
import rv32i_types::*;
(
    input clk,
    input rst,
	
	// Remove after CP1
    input 					instr_mem_resp,
    input rv32i_word 	instr_mem_rdata,
	input 					data_mem_resp,
    input rv32i_word 	data_mem_rdata, 
    output logic 			instr_read,
	output rv32i_word 	instr_mem_address,
    output logic 			data_read,
    output logic 			data_write,
    output logic [3:0] 	data_mbe,
    output rv32i_word 	data_mem_address,
    output rv32i_word 	data_mem_wdata

	
	// For CP2
	/* 
    input pmem_resp,
    input [63:0] pmem_rdata,

	To physical memory
    output logic pmem_read,
    output logic pmem_write,
    output rv32i_word pmem_address,
    output [63:0] pmem_wdata
	*/
);

cpu cpu (

    .clk(clk),
    .rst(rst),
	
    /* I-Cache Ports */
    .instr_read(instr_read),
    .instr_mem_address(instr_mem_address),
    .instr_mem_rdata(instr_mem_rdata),
    .instr_mem_resp(instr_mem_resp),


    /* D-Cache Ports */
    .data_read(data_read),
    .data_write(data_write),
    .data_mem_address(data_mem_address),
    .data_mem_rdata(data_mem_rdata), 
    .data_mbe(data_mbe),
    .data_mem_wdata(data_mem_wdata),
	.data_mem_resp(data_mem_resp)

);

endmodule : mp4