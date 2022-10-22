`define BAD_MUX_SEL $display("%0d: %s:  %0t: Illegal MUX Select", `__LINE__, `__FILE__, $time)

module cpu 
import rv32i_types::*;    
(
    input clk,
    input rst,
	
    /* I-Cache Ports */
    output logic instr_read,
    output rv32i_word instr_mem_address,
    input rv32i_word instr_mem_rdata,
    input logic instr_mem_resp,


    /* D-Cache Ports */
    output logic data_read,
    output logic data_write,
    output rv32i_word data_mem_address,
    input rv32i_word data_mem_rdata, 
    output logic [3:0] data_mbe,
    output rv32i_word data_mem_wdata,
	input logic data_mem_resp

);

pcmux::pcmux_sel_t pc_MUX_sel;

rv32i_word alu_out;
rv32i_word target_address;

rv32i_word pc_mux_out;
rv32i_word cmp_mux_out;
rv32i_word alu_1_mux_out;
rv32i_word alu_2_mux_out;

rv32i_word regfile_mux_out;

/* Pipeline Register I/O */
if_id_pipeline_reg if_id_in;
id_ex_pipeline_reg id_ex_in;
ex_mem_pipeline_reg ex_mem_in;
mem_wb_pipeline_reg mem_wb_in;

if_id_pipeline_reg if_id_out;
id_ex_pipeline_reg id_ex_out;
ex_mem_pipeline_reg ex_mem_out;
mem_wb_pipeline_reg mem_wb_out;

/****************************** FETCH ******************************/ 

pc_register PC(
    .clk(clk),
    .rst(rst),
    .load(1'b1),  // possible_error
    .in(pc_mux_out),
    .out(if_id_in.pc)
);

if_id_reg if_id_reg (
    .clk(clk),
    .rst(rst),
    .flush(1'b0),
    .load(1'b1),
    .in(if_id_in),//come from instruction fetch
    .out(if_id_out)
);



/****************************** DECODE ******************************/ 

regfile regfile (
    .clk(clk),
    .rst(rst),
    .load(mem_wb_out.ctrl.load_regfile), // from WB stage
    .in(regfile_mux_out), // from regfilemux
    .src_a(if_id_out.ir[19:15]), //from decode stage reading 
    .src_b(if_id_out.ir[24:20]), //from decode reading 
    .dest(mem_wb_out.ctrl.rd_id),  //from decode stage reading 
    .reg_a(id_ex_in.rs1_out), //output ---> input into id_ex
    .reg_b(id_ex_in.rs2_out) //output ----> input into id_ex
);

immediate_gen immediate_gen (
    .ir(if_id_out.ir),
    .imm(id_ex_in.imm)
);

control_rom control_rom (
    .opcode(rv32i_opcode'(if_id_out.ir[6:0])),
    .funct3(if_id_out.ir[14:12]),
    .funct7(if_id_out.ir[31:25]),
    .rs1_id(if_id_out.ir[19:15]), 
    .rs2_id(if_id_out.ir[24:20]), 
    .rd_id(if_id_out.ir[11:7]),
    .ctrl(id_ex_in.ctrl)
);

cmp cmp (
    .cmpop(id_ex_in.ctrl.cmpop),   // comes from control_word generation
    .a(id_ex_in.rs1_out), 
    .b(cmp_mux_out),
    .f(id_ex_in.br_en)     // output to id_ex stage
);

id_ex_reg id_ex_reg (
    .clk(clk),
    .rst(rst),
    .flush(1'b0),
    .load(1'b1),
    .in(id_ex_in), //come from decode combinational + passed along values
    .out(id_ex_out) 
);


/****************************** EXECUTE ******************************/ 

alu alu (
    .aluop(id_ex_out.ctrl.aluop),
    .a(alu_1_mux_out), 
    .b(alu_2_mux_out),
    .f(alu_out)
);

mask_gen mask_gen (
    .alu_out(alu_out), 
    .funct3(id_ex_out.ctrl.funct3), 
    .write_read_mask(ex_mem_in.write_read_mask)
);

ex_mem_reg ex_mem_reg (
    .clk(clk),
    .rst(rst),
    .flush(1'b0),
    .load(1'b1),
    .in(ex_mem_in), //come from ex combinational + passed along values
    .out(ex_mem_out)
);

/****************************** MEMORY ******************************/ 

mem_wb_reg mem_wb_reg (
    .clk(clk),
    .rst(rst),
    .flush(1'b0),
    .load(1'b1),
    .in(mem_wb_in), //come from mem + passed along values
    .out(mem_wb_out) //to wb combinational
);

/****************************** WRITEBACK ******************************/ 






/****************************** ASSIGNMENTS ******************************/ 


/* assign ports for I-cache */
assign instr_read = 1'b1; // possible_error: eval later
assign instr_mem_address = if_id_in.pc;
assign if_id_in.ir = instr_mem_rdata; //IR value from I-Cache
// possible_error: ignore instr_mem_resp for magic memory.

/* assign ports for D-cache */
assign data_read = ex_mem_out.ctrl.mem_read;
assign data_write = ex_mem_out.ctrl.mem_write;
assign data_mem_address = ex_mem_out.alu_out_address;
assign mem_wb_in.MDR = data_mem_rdata;
assign data_mbe = ex_mem_out.write_read_mask;
assign data_mem_wdata = ex_mem_out.mem_data_out;
// possible_error: ignore data_mem_resp for magic memory.

/* id_ex pipeline reg assignments */
assign id_ex_in.pc = if_id_out.pc;

/* ex_mem pipeline reg assignments */
assign ex_mem_in.pc = id_ex_out.pc;
assign ex_mem_in.alu_out = alu_out;
assign ex_mem_in.alu_out_address = {alu_out[31:2], 2'b0};
assign ex_mem_in.br_en = id_ex_out.br_en;
assign ex_mem_in.imm = id_ex_out.imm;
assign ex_mem_in.ctrl = id_ex_out.ctrl;

/* mem_wb pipeline reg assignments */
assign mem_wb_in.pc = ex_mem_out.pc;
assign mem_wb_in.alu_out = ex_mem_out.alu_out;
assign mem_wb_in.write_read_mask = ex_mem_out.write_read_mask;
assign mem_wb_in.br_en = ex_mem_out.br_en;
assign mem_wb_in.imm = ex_mem_out.imm;
assign mem_wb_in.ctrl = ex_mem_out.ctrl;

/* Assign PC MUX selection signal in ID stage */
assign pc_MUX_sel[0] = (id_ex_in.br_en && (rv32i_opcode'(if_id_out.ir[6:0]) == op_br) ) || (rv32i_opcode'(if_id_out.ir[6:0]) == op_jal);
assign pc_MUX_sel[1] = (rv32i_opcode'(if_id_out.ir[6:0]) == op_jalr) ? 1'b1 : 1'b0;


/****************************** MUXES ******************************/ 

// possible_error: Not supporting JALR.
assign target_address = if_id_out.pc + id_ex_in.imm;
always_comb begin : PCMUX

    pc_mux_out = '0;

    unique case (pc_MUX_sel)
        pcmux::pc_plus4      : pc_mux_out = if_id_in.pc + 4;
        pcmux::adder_out     : pc_mux_out = target_address;
        pcmux::adder_mod2    : pc_mux_out = {target_address[31:1], 1'b0};
        default: ;
    endcase
end


always_comb begin : CMPMUX

    cmp_mux_out = '0;

    unique case(id_ex_in.ctrl.cmp_MUX_sel)
        cmpmux::rs2_out : cmp_mux_out = id_ex_in.rs2_out;
        cmpmux::imm     : cmp_mux_out = id_ex_in.imm;
        default: ;
    endcase
end

always_comb begin : ALU1MUX 

    alu_1_mux_out = '0;

    unique case (id_ex_out.ctrl.alu_1_MUX_sel)
        alumux::rs1_out :     alu_1_mux_out = id_ex_out.rs1_out;
        alumux::pc_out  :     alu_1_mux_out = id_ex_out.pc;
        default: ;
    endcase
end

always_comb begin : ALU2MUX

    alu_2_mux_out = '0;
    
    unique case (id_ex_out.ctrl.alu_2_MUX_sel)
        alumux::imm     : alu_2_mux_out = id_ex_out.imm;
        alumux::rs2_out : alu_2_mux_out = id_ex_out.rs2_out;
        default: ;
    endcase
end


always_comb begin : MEMWDATAMUX

    ex_mem_in.mem_data_out = '0;

    unique case (ex_mem_in.write_read_mask)

        4'b0001 : ex_mem_in.mem_data_out = {24'b0, id_ex_out.rs2_out[7:0]};
        4'b0010 : ex_mem_in.mem_data_out = {16'b0, id_ex_out.rs2_out[7:0], 8'b0};
        4'b0100 : ex_mem_in.mem_data_out = {8'b0, id_ex_out.rs2_out[7:0], 16'b0};
        4'b1000 : ex_mem_in.mem_data_out = {id_ex_out.rs2_out[7:0], 24'b0};
        4'b0011 : ex_mem_in.mem_data_out = {16'b0, id_ex_out.rs2_out[15:0]};
        4'b1100 : ex_mem_in.mem_data_out = {id_ex_out.rs2_out[15:0], 16'b0};
        4'b1111 : ex_mem_in.mem_data_out = id_ex_out.rs2_out;
        default: ;
    endcase

end


always_comb begin : REGFILEMUX

    regfile_mux_out = '0;
    
    unique case (mem_wb_out.ctrl.regfile_MUX_sel)
        regfilemux::alu_out : regfile_mux_out = mem_wb_out.alu_out;
        regfilemux::br_en   : regfile_mux_out = {{31{1'b0}}, mem_wb_out.br_en};
        regfilemux::imm     : regfile_mux_out = mem_wb_out.imm;
        regfilemux::load    : 
        begin
            case (load_funct3_t'(mem_wb_out.ctrl.funct3))
                lb: 
                begin  
                    unique case(mem_wb_out.write_read_mask)
                        4'b0001: regfile_mux_out = {{24{mem_wb_out.MDR[7]}}, mem_wb_out.MDR[7:0]};
                        4'b0010: regfile_mux_out = {{24{mem_wb_out.MDR[15]}}, mem_wb_out.MDR[15:8]};
                        4'b0100: regfile_mux_out = {{24{mem_wb_out.MDR[23]}}, mem_wb_out.MDR[23:16]};
                        4'b1000: regfile_mux_out = {{24{mem_wb_out.MDR[31]}}, mem_wb_out.MDR[31:24]};
                    endcase
                end
                lbu:
                begin
                    unique case(mem_wb_out.write_read_mask)
                        4'b0001: regfile_mux_out = {24'b0, mem_wb_out.MDR[7:0]};
                        4'b0010: regfile_mux_out = {24'b0, mem_wb_out.MDR[15:8]};
                        4'b0100: regfile_mux_out = {24'b0, mem_wb_out.MDR[23:16]};
                        4'b1000: regfile_mux_out = {24'b0, mem_wb_out.MDR[31:24]};
                    endcase
                end
                lh:
                begin
                    unique case(mem_wb_out.write_read_mask)
                        4'b0011: regfile_mux_out = {{16{mem_wb_out.MDR[15]}}, mem_wb_out.MDR[15:0]};
                        4'b1100: regfile_mux_out = {{16{mem_wb_out.MDR[31]}}, mem_wb_out.MDR[31:16]};
                    endcase
                end
                lhu: 
                begin
                    unique case(mem_wb_out.write_read_mask)
                        4'b0011: regfile_mux_out = {16'b0, mem_wb_out.MDR[15:0]};
                        4'b1100: regfile_mux_out = {16'b0, mem_wb_out.MDR[31:16]};
                    endcase
                end
                lw: regfile_mux_out = mem_wb_out.MDR;
            endcase
        end
        regfilemux::pc_plus4    : regfile_mux_out = mem_wb_out.pc + 4;
        default: ;
    endcase
end


endmodule : cpu