module stall_control_unit
import rv32i_types::*; 
(

    /* Cache Responses */
    input logic instr_mem_resp,
    input logic data_mem_resp,

    /* Control Words*/
    input rv32i_control_word id_ex_in_ctrl,
    input logic id_ex_in_br_en,
    input rv32i_control_word id_ex_out_ctrl,
    input rv32i_control_word ex_mem_out_ctrl,
    input rv32i_control_word mem_wb_out_ctrl,

    /* Pipeline Register Load Signals*/
    output logic load_pc,
    output logic if_id_reg_load,
    output logic id_ex_reg_load,
    output logic ex_mem_reg_load,
    output logic mem_wb_reg_load,
    
    /* Pipeline Register Flush Signals*/
    output logic if_id_reg_flush,
    output logic id_ex_reg_flush,
    output logic ex_mem_reg_flush,
    output logic mem_wb_reg_flush,

    /* MUX Selection */
    output irmux::irmux_sel_t ir_MUX_sel
);



logic branch_mispredict;

assign branch_mispredict = id_ex_in_br_en && (id_ex_in_ctrl.opcode == op_br);

function void set_defaults();
    ir_MUX_sel = irmux::instr_mem_rdata;
    load_pc = 1'b1;

    if_id_reg_load = 1'b1;
    id_ex_reg_load = 1'b1;
    ex_mem_reg_load = 1'b1;
    mem_wb_reg_load = 1'b1;

    if_id_reg_flush = 1'b0;
    id_ex_reg_flush = 1'b0;
    ex_mem_reg_flush = 1'b0;
    mem_wb_reg_flush = 1'b0;
endfunction


function void pipeline_load(logic load_if_id, logic load_id_ex, logic load_ex_mem, logic load_mem_wb);
    //Specify pipeline reg load values 
    if_id_reg_load = load_if_id;
    id_ex_reg_load = load_id_ex;
    ex_mem_reg_load = load_ex_mem;
    mem_wb_reg_load = load_mem_wb;

endfunction


function void pipeline_flush(logic flush_if_id, logic flush_id_ex, logic flush_ex_mem, logic flush_mem_wb);
    if_id_reg_flush = flush_if_id;
    id_ex_reg_flush = flush_id_ex;
    ex_mem_reg_flush = flush_ex_mem;
    mem_wb_reg_flush = flush_mem_wb;
endfunction

always_comb
begin
    set_defaults();
    
    /* Instruction Cache Miss */ 
    if(~instr_mem_resp)
    begin
        load_pc = 1'b0;
        pipeline_load(1'b1, 1'b1, 1'b1, 1'b1);
        pipeline_flush(1'b0, 1'b0, 1'b0, 1'b0);
        ir_MUX_sel = irmux::nop;
    end

    /* Data Cache Miss */
    if(data_mem_resp == 1'b0 && (ex_mem_out_ctrl.mem_read == 1'b1 || ex_mem_out_ctrl.mem_write == 1'b1))
    begin
        load_pc = 1'b0;
        //Halt pipeline
        pipeline_load(1'b0, 1'b0, 1'b0, 1'b0);
    end

    /* (Need CMP/ADDR Adder) after (Need ALU) */
    if((id_ex_out_ctrl.opcode == op_reg && arith_funct3_t'(id_ex_out_ctrl.funct3) != slt)  ||
       (id_ex_out_ctrl.opcode == op_reg && arith_funct3_t'(id_ex_out_ctrl.funct3) != sltu) ||
       (id_ex_out_ctrl.opcode == op_imm && arith_funct3_t'(id_ex_out_ctrl.funct3) != slt)  ||
       (id_ex_out_ctrl.opcode == op_imm && arith_funct3_t'(id_ex_out_ctrl.funct3) != sltu) ||
       id_ex_out_ctrl.opcode == op_auipc)
    begin
        if(id_ex_in_ctrl.opcode == op_br || 
          (id_ex_in_ctrl.opcode == op_reg && arith_funct3_t'(id_ex_in_ctrl.funct3) == slt)  ||
          (id_ex_in_ctrl.opcode == op_reg && arith_funct3_t'(id_ex_in_ctrl.funct3) == sltu) ||
          (id_ex_in_ctrl.opcode == op_imm && arith_funct3_t'(id_ex_in_ctrl.funct3) == slt)  ||
          (id_ex_in_ctrl.opcode == op_imm && arith_funct3_t'(id_ex_in_ctrl.funct3) == sltu))
        begin
            if((id_ex_out_ctrl.rd_id == id_ex_in_ctrl.rs1_id || id_ex_out_ctrl.rd_id == id_ex_in_ctrl.rs2_id) && (id_ex_out_ctrl.rd_id != 0))
            begin
                load_pc = 1'b0;
                pipeline_load(1'b0, 1'b1, 1'b1, 1'b1);
                pipeline_flush(1'b0, 1'b1, 1'b0, 1'b0);
                // if_id_reg_load = 1'b0;
                // id_ex_reg_flush = 1'b1;
                
            end
        end

        if(id_ex_in_ctrl.opcode == op_jalr)
        begin
            if((id_ex_out_ctrl.rd_id == id_ex_in_ctrl.rs1_id) && (id_ex_out_ctrl.rd_id != 0))
            begin
                load_pc = 1'b0;
                pipeline_load(1'b0, 1'b1, 1'b1, 1'b1);
                pipeline_flush(1'b0, 1'b1, 1'b0, 1'b0);
                // if_id_reg_load = 1'b0;
                // id_ex_reg_flush = 1'b1;
            end
        end

    end


    
    /* (Need CMP/ADDR Adder) after LD */
    if (id_ex_out_ctrl.opcode == op_load)
    begin
        if(id_ex_in_ctrl.opcode == op_br || 
          (id_ex_in_ctrl.opcode == op_reg && arith_funct3_t'(id_ex_in_ctrl.funct3) == slt)  ||
          (id_ex_in_ctrl.opcode == op_reg && arith_funct3_t'(id_ex_in_ctrl.funct3) == sltu) ||
          (id_ex_in_ctrl.opcode == op_imm && arith_funct3_t'(id_ex_in_ctrl.funct3) == slt)  ||
          (id_ex_in_ctrl.opcode == op_imm && arith_funct3_t'(id_ex_in_ctrl.funct3) == sltu))
        begin
            if((id_ex_out_ctrl.rd_id == id_ex_in_ctrl.rs1_id || id_ex_out_ctrl.rd_id == id_ex_in_ctrl.rs2_id) && (id_ex_out_ctrl.rd_id != 0))
            begin
                load_pc = 1'b0;
                pipeline_load(1'b0, 1'b1, 1'b1, 1'b1);
                pipeline_flush(1'b0, 1'b1, 1'b0, 1'b0);
                // if_id_reg_load = 1'b0;
                // id_ex_reg_flush = 1'b1;
            end
        end

        if(id_ex_in_ctrl.opcode == op_jalr)
        begin
            if((id_ex_out_ctrl.rd_id == id_ex_in_ctrl.rs1_id) && (id_ex_out_ctrl.rd_id != 0))
            begin
                load_pc = 1'b0;
                pipeline_load(1'b0, 1'b1, 1'b1, 1'b1);
                pipeline_flush(1'b0, 1'b1, 1'b0, 1'b0);
                // if_id_reg_load = 1'b0;
                // id_ex_reg_flush = 1'b1;
            end
        end
    end

    if(ex_mem_out_ctrl.opcode == op_load)
    begin
        if(id_ex_in_ctrl.opcode == op_br || 
          (id_ex_in_ctrl.opcode == op_reg && arith_funct3_t'(id_ex_in_ctrl.funct3) == slt)  ||
          (id_ex_in_ctrl.opcode == op_reg && arith_funct3_t'(id_ex_in_ctrl.funct3) == sltu) ||
          (id_ex_in_ctrl.opcode == op_imm && arith_funct3_t'(id_ex_in_ctrl.funct3) == slt)  ||
          (id_ex_in_ctrl.opcode == op_imm && arith_funct3_t'(id_ex_in_ctrl.funct3) == sltu))
        begin
            if((ex_mem_out_ctrl.rd_id == id_ex_in_ctrl.rs1_id || ex_mem_out_ctrl.rd_id == id_ex_in_ctrl.rs2_id) && (ex_mem_out_ctrl.rd_id != 0))
            begin
                load_pc = 1'b0;
                pipeline_load(1'b0, 1'b1, 1'b1, 1'b1);
                pipeline_flush(1'b0, 1'b1, 1'b0, 1'b0);
                // if_id_reg_load = 1'b0;
                // id_ex_reg_flush = 1'b1;
            end
        end

        if(id_ex_in_ctrl.opcode == op_jalr)
        begin
            if((ex_mem_out_ctrl.rd_id == id_ex_in_ctrl.rs1_id) && (ex_mem_out_ctrl.rd_id != 0))
            begin
                load_pc = 1'b0;
                pipeline_load(1'b0, 1'b1, 1'b1, 1'b1);
                pipeline_flush(1'b0, 1'b1, 1'b0, 1'b0);
                // if_id_reg_load = 1'b0;
                // id_ex_reg_flush = 1'b1;
            end
        end
    end

    /* (Need ALU) after LD */
    if(ex_mem_out_ctrl.opcode == op_load)
    begin
        if((id_ex_out_ctrl.opcode == op_reg && arith_funct3_t'(id_ex_out_ctrl.funct3) != slt)  ||
           (id_ex_out_ctrl.opcode == op_reg && arith_funct3_t'(id_ex_out_ctrl.funct3) != sltu) ||
           (id_ex_out_ctrl.opcode == op_imm && arith_funct3_t'(id_ex_out_ctrl.funct3) != slt)  ||
           (id_ex_out_ctrl.opcode == op_imm && arith_funct3_t'(id_ex_out_ctrl.funct3) != sltu))
        begin
            if((ex_mem_out_ctrl.rd_id == id_ex_out_ctrl.rs1_id || ex_mem_out_ctrl.rd_id == id_ex_out_ctrl.rs2_id) && (ex_mem_out_ctrl.rd_id != 0))
            begin
                load_pc = 1'b0;
                pipeline_load(1'b0, 1'b0, 1'b1, 1'b1);
                pipeline_flush(1'b0, 1'b0, 1'b1, 1'b0);
                // if_id_reg_load = 1'b0;
                // id_ex_reg_load = 1'b0;
                // ex_mem_reg_flush = 1'b1;
            end
        end
        if (id_ex_out_ctrl.opcode == op_store)
        begin
            if ((ex_mem_out_ctrl.rd_id == id_ex_out_ctrl.rs1_id) && (ex_mem_out_ctrl.rd_id != 0))
            begin
                load_pc = 1'b0;
                pipeline_load(1'b0, 1'b0, 1'b1, 1'b1);
                pipeline_flush(1'b0, 1'b0, 1'b1, 1'b0);
                // if_id_reg_load = 1'b0;
                // id_ex_reg_load = 1'b0;
                // ex_mem_reg_flush = 1'b1;
            end
        end

    end

    /* Branch Mispredict or Unconditional Jumps */
    if(branch_mispredict || id_ex_in_ctrl.opcode == op_jal || id_ex_in_ctrl.opcode == op_jalr)
    begin
        ir_MUX_sel = irmux::nop;
    end
end

endmodule : stall_control_unit