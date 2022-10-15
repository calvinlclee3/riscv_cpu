module cpu 
import rv32i_types::*;    
(

);

// wires
rv32i_word cmp_mux_out;
rv32i_word pc_mux_out;
rv32i_word alu_1_mux_out;
rv32i_word alu_2_mux_out;
rv32i_word alu_out;
rv32i_word regfile_mux_out;

pcmux_sel_t pc_mux_sel;

// pipeline reg inout
if_id_pipeline_reg if_id_in;
id_ex_pipeline_reg id_ex_in;


if_id_pipeline_reg if_id_out;
id_ex_pipeline_reg id_ex_out;
ex_mem_pipeline_reg ex_mem_out;
mem_wb_pipeline_reg mem_wb_out;

/****************************** FETCH ******************************/ 

pc_register PC(
    .clk(clk),
    .rst(rst),
    .load(),
    .in(pc_mux_out),
    .out(if_id_in.pc)
);

if_id_reg if_id_reg (
    .clk(clk),
    .rst(rst),
    .flush(),
    .load(),
    .in(if_id_in),//come from instruction fetch
    .out(if_id_out)
);



/****************************** DECODE ******************************/ 

regfile regfile (
    .clk(clk),
    .rst(rst),
    .load(mem_wb_out.ctrl.load_regfile)//from WB stage
    .in(regfile_mux_out), //from regfilemux
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
    .flush(),
    .load(),
    .in(id_ex_in), //come from decode combinational + passed along values
    .out(id_ex_out) 
);




/****************************** EXECUTE ******************************/ 

mask_gen mask_gen (
    .alu_out(),
    .funct3(),
    .write_read_mask()
);

alu alu (
    .aluop(id_ex_out.ctrl.aluop),
    .a(alu_1_mux_out), 
    .b(alu_2_mux_out),
    .f(alu_out)
);



ex_mem_reg ex_mem_reg (
    .clk(clk),
    .rst(rst),
    .flush(),
    .load(),
    .in(), //come from ex combinational + passed along values
    .out(ex_mem_out)
);

/****************************** MEMORY ******************************/ 

mem_wb_reg mem_wb_reg (
    .clk(clk),
    .rst(rst),
    .flush(),
    .load(),
    .in(), //come from mem + passed along values
    .out(mem_wb_out) //to wb combinational
);

/****************************** WRITEBACK ******************************/ 








/****************************** MUXES ******************************/ 


assign pc_mux_sel[0] = (id_ex_in.br_en && (rv32i_opcode'(if_id_out.ir[6:0]) == op_br) ) || (rv32i_opcode'(if_id_out.ir[6:0]) == op_jal);
assign pc_mux_sel[1] = (rv32i_opcode'(if_id_out.ir[6:0]) == op_jalr) ? 1'b1: 1'b0;

assign ex_mem_in.alu_out = alu_out;
assign ex_mem_in.alu_out_address = {alu_out[31:2], 2'b0};

// CP1_possible_error: missing assign statements for "passthrough" signals between pipeline registers

always_comb begin : PCMUX
    pc_mux_out = if_id_in.pc + 4;
    unique case (pc_mux_sel)
        pcmux::pc_plus4      : pc_mux_out = if_id_in.pc + 4;
        pcmux::adder_out     : pc_mux_out = if_id_out.pc + id_ex_in.imm;
        pcmux::adder_mod2    : pc_mux_out = {(if_id_out.pc + id_ex_in.imm)[31:1], 1'b0};
    endcase
end


always_comb begin : CMPMUX
    cmp_mux_out = id_ex_in.rs2_out;
    unique case(id_ex_in.ctrl.cmp_MUX_sel)
        cmpmux::rs2_out : cmp_mux_out = id_ex_in.rs2_out;
        cmpmux::imm     : cmp_mux_out = id_ex_in.imm;
    endcase
end

always_comb begin : ALU1MUX 
    alu_1_mux_out = id_ex_out.rs1_out;
    unique case (id_ex_out.ctrl.alu_1_MUX_sel)
        alumux::rs1_out :     alu_1_mux_out = id_ex_out.rs1_out;
        alumux::pc_out  :     alu_1_mux_out = id_ex_out.pc;
    endcase
end

always_comb begin : ALU2MUX
    alu_2_mux_out = id_ex_out.imm;
    unique case (id_ex_out.ctrl.alu_2_MUX_sel)
        alumux::imm     : alu_2_mux_out = id_ex_out.imm;
        alumux::rs2_out : alu_2_mux_out = id_ex_out.rs2_out;
    endcase
end

// CP1_possible_error
always_comb begin
    unique case (ex_mem_in.ctrl.write_read_mask)
        2'b00     : 
        2'b01     : 
        2'b10     :
        default   : 
    endcase

end

// CP1_possible_error
always_comb begin
    unique case (mem_wb_out.ctrl.regfile_MUX_sel)
        regfilemux::alu_out     : 
        regfilemux::br_en       :
        regfilemux::imm         :
        regfilemux::load        : 
            case (load_funct3'(mem_wb_out.ctrl.funct3))
                lb  : begin  
                        unique case(write_read_mask)
                            4'b0001: regfile_mux_out = 32'(signed'(mdrreg_out[7:0]));
                            4'b0010: regfile_mux_out = 32'(signed'(mdrreg_out[15:8]));
                            4'b0100: regfile_mux_out = 32'(signed'(mdrreg_out[23:16]));
                            4'b1000: regfile_mux_out = 32'(signed'(mdrreg_out[31:24]));
                            default: ;
                        endcase
                    end
                lh  : unique case(write_read_mask)
                        4'b0011: regfile_mux_out = 32'(signed'(mdrreg_out[15:0]));
                        4'b1100: regfile_mux_out = 32'(signed'(mdrreg_out[31:16]));
                        default: ;
                    endcase
                lw  : regfile_mux_out = mdrreg_out;
                lbu : unique case(write_read_mask)
                        4'b0001: regfile_mux_out = mdrreg_out & 32'h000000FF;
                        4'b0010: regfile_mux_out = (mdrreg_out[15:8]) & 32'h000000FF;
                        4'b0100: regfile_mux_out = (mdrreg_out[23:16]) & 32'h000000FF;
                        4'b1000: regfile_mux_out = (mdrreg_out[31:24]) & 32'h000000FF;
                        default: ;
                    endcase
                lhu : unique case(write_read_mask)
                        4'b0011: regfile_mux_out = mdrreg_out & 32'h0000FFFF;
                        4'b1100: regfile_mux_out = (mdrreg_out[31:16]) & 32'h0000FFFF;
                        default: ;
                    endcase
            endcase
        regfilemux::pc_plus4    :
    endcase
end


endmodule : cpu