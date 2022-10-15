import rv32i_types::*;

module control_rom
(
    input rv32i_opcode opcode,
    input [2:0] funct3,
    input [6:0] funct7,
    input rv32i_reg rs1_id, rs2_id, rd_id,
    output rv32i_control_word ctrl
);

branch_funct3_t branch_funct3;
store_funct3_t store_funct3;
load_funct3_t load_funct3;
arith_funct3_t arith_funct3;

assign arith_funct3 = arith_funct3_t'(funct3);
assign branch_funct3 = branch_funct3_t'(funct3);
assign load_funct3 = load_funct3_t'(funct3);
assign store_funct3 = store_funct3_t'(funct3);

function void set_defaults();
    ctrl.opcode = opcode;
    ctrl.funct3 = funct3;
    ctrl.funct7 = funct7;
    ctrl.rs1_id = rs1_id;
    ctrl.rs2_id = rs2_id;
    ctrl.rd_id = rd_id;
    ctrl.aluop = alu_ops'(funct3);
    ctrl.cmpop = branch_funct3_t'(funct3);
    ctrl.cmp_MUX_sel = cmpmux::rs2_out;
    ctrl.alu_1_MUX_sel = alumux::rs1_out;
    ctrl.alu_2_MUX_sel = alumux::imm;
    ctrl.regfile_MUX_sel = regfilemux::alu_out;
    ctrl.load_regfile = 1'b0;
    ctrl.load_pc = 1'b1;
    ctrl.mem_read = 1'b0;
    ctrl.mem_write = 1'b0;
endfunction

function void setALU(alumux::alumux1_sel_t sel1, alumux::alumux2_sel_t sel2, logic setop, alu_ops op);
    ctrl.alu_1_MUX_sel = sel1;
    ctrl.alu_2_MUX_sel = sel2;

    if (setop)
        ctrl.aluop = op; 
endfunction

function automatic void setCMP(cmpmux::cmpmux_sel_t sel, branch_funct3_t op);
    ctrl.cmpop = op;
    ctrl.cmp_MUX_sel = sel;
endfunction

function void loadPC(logic load_pc);
    ctrl.load_pc = load_pc;
endfunction

function void loadRegfile(regfilemux::regfilemux_sel_t sel);
    ctrl.load_regfile = 1'b1;
    ctrl.regfile_MUX_sel = sel;
endfunction

function void mem_read()
    ctrl.mem_read = 1'b1;
endfunction

function void mem_write()
    ctrl.mem_write = 1'b1;
endfunction

always_comb begin
    /* Default assignments */
    set_defaults();

    /* Assign control signals based on opcode */
    case(opcode)
        op_lui : begin
            loadRegfile(imm);
        end
        op_auipc : begin
            setALU(pc_out, imm, 1, alu_add);
            loadRegfile(alu_out);
        end
        op_jal   : begin
            setALU(pc_out, imm, 1, alu_add);
            loadRegfile(pc_plus4);
        end
        op_jalr  : begin
            setALU(rs1_out, imm, 1, alu_add);
            loadRegfile(pc_plus4);
        end
        op_br    : begin
            setCMP(rs2_out, branch_funct3);
            setALU(pc_out, imm, 1, alu_add);

        end

        op_load  : begin
            setALU(rs1_out, imm, 1, alu_add);
            loadRegfile(load);
            mem_read();
        end

        op_store : begin
            setALU(rs1_out, imm, 1, alu_add);
            mem_write();
        end

        op_imm : begin
            unique case (arith_funct3)
                    slt:
                    begin
                        setCMP(imm, blt);
                        loadRegfile(br_en);
                    end
                    sltu : 
                    begin
                        setCMP(imm, bltu);
                        loadRegfile(br_en);
                    end
                    sr :
                    begin
                        setALU(rs1_out, imm, 1, (funct7[5]) ? alu_sra: arith_funct3);
                        loadRegfile(alu_out);
                    end
                    add, sll, axor, aor, aand :
                    begin
                        setALU(rs1_out, imm, 1, arith_funct3);
                        loadRegfile(alu_out);
                    end

            endcase
        end

        op_reg : begin
            unique case (arith_funct3)
                slt:
                begin
                    setCMP(rs2_out, blt);
                    loadRegfile(br_en);
                end
                sltu : 
                begin
                    setCMP(rs2_out, bltu);
                    loadRegfile(br_en);
                end
                sr :
                begin
                    setALU(rs1_out, rs2_out, 1, (funct7[5]) ? alu_sra : arith_funct3);
                    loadRegfile(alu_out);
                end
                add : 
                begin
                    setALU(rs1_out, rs2_out, 1, (funct7[5]) ? alu_sub : arith_funct3);
                    loadRegfile(alu_out);
                end

                sll, axor, aor, aand :
                begin
                    setALU(rs1_out, rs2_out, 1, arith_funct3);
                    loadRegfile(alu_out);
                end

            endcase
        end

    endcase
end
endmodule : control_rom