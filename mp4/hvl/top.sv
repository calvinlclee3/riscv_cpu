module mp4_tb;
import rv32i_types::*;
`timescale 1ns/10ps

/********************* Do not touch for proper compilation *******************/
// Instantiate Interfaces
tb_itf itf();
rvfi_itf rvfi(itf.clk, itf.rst);

// Instantiate Testbench
source_tb tb(
    .magic_mem_itf(itf),
    .mem_itf(itf),
    .sm_itf(itf),
    .tb_itf(itf),
    .rvfi(rvfi)
);

// Dump signals
initial begin
    $fsdbDumpfile("dump.fsdb");
    $fsdbDumpvars(0, mp4_tb, "+all");
end
/****************************** End do not touch *****************************/


/************************ Signals necessary for monitor **********************/
// This section not required until CP2

// Set high when a valid instruction is modifying regfile or PC
assign rvfi.commit = 0; 
// Set high when target PC == Current PC for a branch
assign rvfi.halt = dut.cpu.PC.load && (dut.cpu.mem_wb_out.pc == dut.cpu.mem_wb_out.target_address) && (rv32i_opcode'(dut.cpu.mem_wb_out.ctrl.opcode) == op_br || rv32i_opcode'(dut.cpu.mem_wb_out.ctrl.opcode) == op_jal || rv32i_opcode'(dut.cpu.mem_wb_out.ctrl.opcode) == op_jalr) ; 
initial rvfi.order = 0;
always @(posedge itf.clk iff rvfi.commit) rvfi.order <= rvfi.order + 1; // Modify for OoO


assign rvfi.rs1_addr = dut.cpu.mem_wb_out.ctrl.rs1_id;
assign rvfi.rs2_addr = dut.cpu.mem_wb_out.ctrl.rs2_id;
assign rvfi.rd_addr = dut.cpu.mem_wb_out.ctrl.rd_id;
assign rvfi.load_regfile = dut.cpu.mem_wb_out.ctrl.load_regfile;
assign rvfi.rd_wdata = dut.cpu.regfile_MUX_out;
assign rvfi.pc_rdata = dut.cpu.mem_wb_out.pc;
assign rvfi.mem_addr = {dut.cpu.mem_wb_out.alu_out[31:1], 2'b0};
assign rvfi.mem_rmask = dut.cpu.mem_wb_out.write_read_mask;
assign rvfi.mem_wmask = dut.cpu.mem_wb_out.write_read_mask;
assign rvfi.mem_rdata = dut.cpu.mem_wb_out.MDR;
// possible_error: For an instruction that reads no rs1/rs2 register, this output can have an arbitrary value. However, if this output is nonzero then rvfi_rs1_rdata must carry the value stored in that register in the pre-state.
/*
Instruction and trap:
    rvfi.inst  [instruction word for the retired instruction: not avail at WB]
    rvfi.trap  [This honestly not that useful]

Regfile:
    rvfi.rs1_addr [DONE]
    rvfi.rs2_addr [DONE]
    rvfi.rs1_rdata [value of register rs1 before execution of instruction: not avail at WB]
    rvfi.rs2_rdata [value of register rs2 before execution of instruction: not avail at WB]
    rvfi.load_regfile [DONE]
    rvfi.rd_addr [DONE]
    rvfi.rd_wdata [DONE]

PC:
    rvfi.pc_rdata [DONE]
    rvfi.pc_wdata [addr of the next instruction, but we might not know because the instr in ex_mem might be a hardware inserted NOP, not the actual next instr]

Memory:
    rvfi.mem_addr [DONE]
    rvfi.mem_rmask [DONE]
    rvfi.mem_wmask [DONE]
    rvfi.mem_rdata [DONE]
    rvfi.mem_wdata [data written to memory: not avail at WB]

Please refer to rvfi_itf.sv for more information.
*/

/**************************** End RVFIMON signals ****************************/

/********************* Assign Shadow Memory Signals Here *********************/
// This section not required until CP2
/*
The following signals need to be set:
icache signals:
    itf.inst_read
    itf.inst_addr
    itf.inst_resp
    itf.inst_rdata

dcache signals:
    itf.data_read
    itf.data_write
    itf.data_mbe
    itf.data_addr
    itf.data_wdata
    itf.data_resp
    itf.data_rdata

Please refer to tb_itf.sv for more information.
*/

/*********************** End Shadow Memory Assignments ***********************/

// Set this to the proper value
assign itf.registers = '{default: '0};

/*********************** Instantiate your design here ************************/
/*
The following signals need to be connected to your top level for CP2:
Burst Memory Ports:
    itf.mem_read
    itf.mem_write
    itf.mem_wdata
    itf.mem_rdata
    itf.mem_addr
    itf.mem_resp

Please refer to tb_itf.sv for more information.
*/

mp4 dut(
    .clk(itf.clk),
    .rst(itf.rst),
    
     // Remove after CP1
    .instr_mem_resp(itf.inst_resp),
    .instr_mem_rdata(itf.inst_rdata),
	.data_mem_resp(itf.data_resp),
    .data_mem_rdata(itf.data_rdata),
    .instr_read(itf.inst_read),
	.instr_mem_address(itf.inst_addr),
    .data_read(itf.data_read),
    .data_write(itf.data_write),
    .data_mbe(itf.data_mbe),
    .data_mem_address(itf.data_addr),
    .data_mem_wdata(itf.data_wdata)


    /* Use for CP2 onwards
    .pmem_read(itf.mem_read),
    .pmem_write(itf.mem_write),
    .pmem_wdata(itf.mem_wdata),
    .pmem_rdata(itf.mem_rdata),
    .pmem_address(itf.mem_addr),
    .pmem_resp(itf.mem_resp)
    */
);
/***************************** End Instantiation *****************************/

endmodule
