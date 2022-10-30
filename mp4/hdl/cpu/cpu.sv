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
idforwardamux::idforwardamux_sel_t id_forward_A_MUX_sel;
idforwardbmux::idforwardbmux_sel_t id_forward_B_MUX_sel;
exforwardamux::exforwardamux_sel_t ex_forward_A_MUX_sel;
exforwardbmux::exforwardbmux_sel_t ex_forward_B_MUX_sel;
wbmemforwardmux::wbmemforwardmux_sel_t wb_mem_forward_MUX_sel;

rv32i_word reg_a_out;
rv32i_word reg_b_out;
rv32i_word alu_out;
rv32i_word target_address;

rv32i_word pc_MUX_out;
rv32i_word ir_MUX_out;
rv32i_word id_forward_A_MUX_out;
rv32i_word id_forward_B_MUX_out;
rv32i_word target_address_MUX_out;
rv32i_word cmp_MUX_out;
rv32i_word ex_forward_A_MUX_out;
rv32i_word ex_forward_B_MUX_out;
rv32i_word alu_1_MUX_out;
rv32i_word alu_2_MUX_out;
rv32i_word wb_mem_forward_MUX_out;
rv32i_word regfile_MUX_out;

/* Pipeline Register I/O */
if_id_pipeline_reg if_id_in;
id_ex_pipeline_reg id_ex_in;
ex_mem_pipeline_reg ex_mem_in;
mem_wb_pipeline_reg mem_wb_in;

if_id_pipeline_reg if_id_out;
id_ex_pipeline_reg id_ex_out;
ex_mem_pipeline_reg ex_mem_out;
mem_wb_pipeline_reg mem_wb_out;

// logic load_pc;
// assign load_pc = instr_mem_resp;
// //for now, will need to add stalling

// //I-Cache Miss

// assign ir



/****************************** FETCH ******************************/ 

pc_register PC(
    .clk(clk),
    .rst(rst),
    .load(1'b1),  // possible_error: stalling require not loading PC register
    .in(pc_MUX_out),
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
    .in(regfile_MUX_out), // from regfilemux
    .src_a(if_id_out.ir[19:15]), //from decode stage reading 
    .src_b(if_id_out.ir[24:20]), //from decode reading 
    .dest(mem_wb_out.ctrl.rd_id),  //from decode stage reading 
    .reg_a(reg_a_out), //output ---> input into id_ex
    .reg_b(reg_b_out) //output ----> input into id_ex
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
    .a(id_forward_A_MUX_out), 
    .b(cmp_MUX_out),
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
    .a(alu_1_MUX_out), 
    .b(alu_2_MUX_out),
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


/****************************** GLOBAL ******************************/ 

forward_control_unit forward_control_unit (

    .id_ex_in_ctrl(id_ex_in.ctrl),
    .id_ex_out_ctrl(id_ex_out.ctrl),
    .ex_mem_out_ctrl(ex_mem_out.ctrl),
    .mem_wb_out_ctrl(mem_wb_out.ctrl),
    
    .id_forward_A_MUX_sel(id_forward_A_MUX_sel),
    .id_forward_B_MUX_sel(id_forward_B_MUX_sel),
    .ex_forward_A_MUX_sel(ex_forward_A_MUX_sel),
    .ex_forward_B_MUX_sel(ex_forward_B_MUX_sel),
    .wb_mem_forward_MUX_sel(wb_mem_forward_MUX_sel) 
);


/****************************** ASSIGNMENTS ******************************/ 


/* assign ports for I-cache */
assign instr_read = 1'b1; // possible_error: eval later (it is possible to always read as long as we dont store the read value)
assign instr_mem_address = if_id_in.pc;
assign if_id_in.ir = ir_MUX_out; //IR value from I-Cache
// possible_error: ignore instr_mem_resp for magic memory.

/* assign ports for D-cache */
assign data_read = ex_mem_out.ctrl.mem_read;
assign data_write = ex_mem_out.ctrl.mem_write;
assign data_mem_address = ex_mem_out.alu_out_address;
assign mem_wb_in.MDR = data_mem_rdata;
assign data_mbe = ex_mem_out.write_read_mask;
// possible_error: ignore data_mem_resp for magic memory.

/* id_ex pipeline reg assignments */
assign id_ex_in.pc = if_id_out.pc;
assign id_ex_in.rs1_out = id_forward_A_MUX_out;
assign id_ex_in.rs2_out = id_forward_B_MUX_out;

/* ex_mem pipeline reg assignments */
assign ex_mem_in.pc = id_ex_out.pc;
assign ex_mem_in.alu_out = alu_out;
assign ex_mem_in.alu_out_address = {alu_out[31:2], 2'b0};
assign ex_mem_in.br_en = id_ex_out.br_en;
assign ex_mem_in.imm = id_ex_out.imm;
assign ex_mem_in.ctrl = id_ex_out.ctrl;
assign ex_mem_in.mem_data_out = ex_forward_B_MUX_out;
assign ex_mem_in.target_address = id_ex_out.target_address;

/* mem_wb pipeline reg assignments */
assign mem_wb_in.pc = ex_mem_out.pc;
assign mem_wb_in.alu_out = ex_mem_out.alu_out;
assign mem_wb_in.write_read_mask = ex_mem_out.write_read_mask;
assign mem_wb_in.br_en = ex_mem_out.br_en;
assign mem_wb_in.imm = ex_mem_out.imm;
assign mem_wb_in.ctrl = ex_mem_out.ctrl;
assign mem_wb_in.target_address = ex_mem_out.target_address;

/* Assign PC MUX selection signal in ID stage */
assign pc_MUX_sel[0] = (id_ex_in.br_en && (rv32i_opcode'(if_id_out.ir[6:0]) == op_br) ) || (rv32i_opcode'(if_id_out.ir[6:0]) == op_jal);
assign pc_MUX_sel[1] = (rv32i_opcode'(if_id_out.ir[6:0]) == op_jalr) ? 1'b1 : 1'b0;


/****************************** MUXES ******************************/ 


assign id_ex_in.target_address = target_address_MUX_out + id_ex_in.imm;
always_comb begin : PCMUX

    pc_MUX_out = '0;

    unique case (pc_MUX_sel)
        pcmux::pc_plus4      : pc_MUX_out = if_id_in.pc + 4;
        pcmux::adder_out     : pc_MUX_out = id_ex_in.target_address;
        pcmux::adder_mod2    : pc_MUX_out = {id_ex_in.target_address[31:1], 1'b0};
        default: ;
    endcase
end

always_comb begin : IRMUX

    ir_MUX_out = '0;

    unique case (irmux::instr_mem_rdata)
        irmux::instr_mem_rdata : ir_MUX_out = instr_mem_rdata;
        irmux::nop             : ir_MUX_out = 32'h00000013;    // NOP
        default:;
    endcase
end

always_comb begin: IDFORWARDAMUX

    id_forward_A_MUX_out = '0;

    unique case (id_forward_A_MUX_sel) // possible_error
        idforwardamux::no_forward      : id_forward_A_MUX_out = reg_a_out;
        idforwardamux::ex_br_en        : id_forward_A_MUX_out = {31'b0, id_ex_out.br_en};
        idforwardamux::ex_imm          : id_forward_A_MUX_out = id_ex_out.imm;
        idforwardamux::mem_pc_plus4    : id_forward_A_MUX_out = ex_mem_out.pc + 4;
        idforwardamux::mem_alu_out     : id_forward_A_MUX_out = ex_mem_out.alu_out;
        idforwardamux::mem_imm         : id_forward_A_MUX_out = ex_mem_out.imm;
        default:;
    endcase
end

always_comb begin: IDFORWARDBMUX

    id_forward_B_MUX_out = '0;

    unique case (id_forward_B_MUX_sel) // possible_error
        idforwardbmux::no_forward      : id_forward_B_MUX_out = reg_b_out;
        idforwardbmux::ex_br_en        : id_forward_B_MUX_out = {31'b0, id_ex_out.br_en};
        idforwardbmux::ex_imm          : id_forward_B_MUX_out = id_ex_out.imm;
        idforwardbmux::mem_pc_plus4    : id_forward_B_MUX_out = ex_mem_out.pc + 4;
        idforwardbmux::mem_alu_out     : id_forward_B_MUX_out = ex_mem_out.alu_out;
        idforwardbmux::mem_imm         : id_forward_B_MUX_out = ex_mem_out.imm;
        default:;
    endcase
end

always_comb begin : TARGETADDRESSMUX

    target_address_MUX_out = '0;

    unique case(id_ex_in.ctrl.target_address_MUX_sel)
        targetaddressmux::pc       : target_address_MUX_out = if_id_out.pc;
        targetaddressmux::rs1_out  : target_address_MUX_out = id_forward_A_MUX_out;
        default: ;
    endcase
end

always_comb begin : CMPMUX

    cmp_MUX_out = '0;

    unique case(id_ex_in.ctrl.cmp_MUX_sel)
        cmpmux::rs2_out : cmp_MUX_out = id_forward_B_MUX_out;
        cmpmux::imm     : cmp_MUX_out = id_ex_in.imm;
        default: ;
    endcase
end

always_comb begin: EXFORWARDAMUX

    ex_forward_A_MUX_out = '0;    

    unique case (ex_forward_A_MUX_sel)
        exforwardamux::no_forward          : ex_forward_A_MUX_out = id_ex_out.rs1_out;
        exforwardamux::mem_alu_out         : ex_forward_A_MUX_out = ex_mem_out.alu_out;
        exforwardamux::mem_imm             : ex_forward_A_MUX_out = ex_mem_out.imm;
        exforwardamux::wb_regfile_MUX_out  : ex_forward_A_MUX_out = regfile_MUX_out;       
        default:;
    endcase
end

always_comb begin: EXFORWARDBMUX

    ex_forward_B_MUX_out = '0;

    unique case (ex_forward_B_MUX_sel)
        exforwardbmux::no_forward          : ex_forward_B_MUX_out = id_ex_out.rs2_out;
        exforwardbmux::mem_alu_out         : ex_forward_B_MUX_out = ex_mem_out.alu_out;
        exforwardbmux::mem_imm             : ex_forward_B_MUX_out = ex_mem_out.imm;
        exforwardbmux::wb_regfile_MUX_out  : ex_forward_B_MUX_out = regfile_MUX_out;
        default:;
    endcase
end

always_comb begin : ALU1MUX 

    alu_1_MUX_out = '0;

    unique case (id_ex_out.ctrl.alu_1_MUX_sel)
        alumux::rs1_out :     alu_1_MUX_out = ex_forward_A_MUX_out;
        alumux::pc_out  :     alu_1_MUX_out = id_ex_out.pc;
        default: ;
    endcase
end

always_comb begin : ALU2MUX

    alu_2_MUX_out = '0;
    
    unique case (id_ex_out.ctrl.alu_2_MUX_sel)
        alumux::imm     : alu_2_MUX_out = id_ex_out.imm;
        alumux::rs2_out : alu_2_MUX_out = ex_forward_B_MUX_out;
        default: ;
    endcase
end


always_comb begin : WBMEMFORWARDMUX

    wb_mem_forward_MUX_out = '0;

    unique case (wb_mem_forward_MUX_sel)
        wbmemforwardmux::no_forward         : wb_mem_forward_MUX_out = ex_mem_out.mem_data_out;
        wbmemforwardmux::regfile_MUX_out    : wb_mem_forward_MUX_out = regfile_MUX_out;
        default:;
    endcase

end

always_comb begin : MEMWDATAMUX

    data_mem_wdata = '0;

    unique case (ex_mem_out.write_read_mask)

        4'b0001 : data_mem_wdata = {24'b0, wb_mem_forward_MUX_out[7:0]};
        4'b0010 : data_mem_wdata = {16'b0, wb_mem_forward_MUX_out[7:0], 8'b0};
        4'b0100 : data_mem_wdata = {8'b0, wb_mem_forward_MUX_out[7:0], 16'b0};
        4'b1000 : data_mem_wdata = {wb_mem_forward_MUX_out[7:0], 24'b0};
        4'b0011 : data_mem_wdata = {16'b0, wb_mem_forward_MUX_out[15:0]};
        4'b1100 : data_mem_wdata = {wb_mem_forward_MUX_out[15:0], 16'b0};
        4'b1111 : data_mem_wdata = wb_mem_forward_MUX_out;
        default: ;
    endcase

end


always_comb begin : REGFILEMUX

    regfile_MUX_out = '0;
    
    unique case (mem_wb_out.ctrl.regfile_MUX_sel)
        regfilemux::alu_out : regfile_MUX_out = mem_wb_out.alu_out;
        regfilemux::br_en   : regfile_MUX_out = {{31{1'b0}}, mem_wb_out.br_en};
        regfilemux::imm     : regfile_MUX_out = mem_wb_out.imm;
        regfilemux::load    : 
        begin
            unique case (load_funct3_t'(mem_wb_out.ctrl.funct3))
                lb: 
                begin  
                    case(mem_wb_out.write_read_mask)
                        4'b0001: regfile_MUX_out = {{24{mem_wb_out.MDR[7]}}, mem_wb_out.MDR[7:0]};
                        4'b0010: regfile_MUX_out = {{24{mem_wb_out.MDR[15]}}, mem_wb_out.MDR[15:8]};
                        4'b0100: regfile_MUX_out = {{24{mem_wb_out.MDR[23]}}, mem_wb_out.MDR[23:16]};
                        4'b1000: regfile_MUX_out = {{24{mem_wb_out.MDR[31]}}, mem_wb_out.MDR[31:24]};
                    endcase
                end
                lbu:
                begin
                    case(mem_wb_out.write_read_mask)
                        4'b0001: regfile_MUX_out = {24'b0, mem_wb_out.MDR[7:0]};
                        4'b0010: regfile_MUX_out = {24'b0, mem_wb_out.MDR[15:8]};
                        4'b0100: regfile_MUX_out = {24'b0, mem_wb_out.MDR[23:16]};
                        4'b1000: regfile_MUX_out = {24'b0, mem_wb_out.MDR[31:24]};
                    endcase
                end
                lh:
                begin
                    case(mem_wb_out.write_read_mask)
                        4'b0011: regfile_MUX_out = {{16{mem_wb_out.MDR[15]}}, mem_wb_out.MDR[15:0]};
                        4'b1100: regfile_MUX_out = {{16{mem_wb_out.MDR[31]}}, mem_wb_out.MDR[31:16]};
                    endcase
                end
                lhu: 
                begin
                    case(mem_wb_out.write_read_mask)
                        4'b0011: regfile_MUX_out = {16'b0, mem_wb_out.MDR[15:0]};
                        4'b1100: regfile_MUX_out = {16'b0, mem_wb_out.MDR[31:16]};
                    endcase
                end
                lw: regfile_MUX_out = mem_wb_out.MDR;
                default:;
            endcase
        end
        regfilemux::pc_plus4    : regfile_MUX_out = mem_wb_out.pc + 4;
        default: ;
    endcase
end


endmodule : cpu