module forward_control_unit
import rv32i_types::*; 
(
    /* Inputs Required for Forwarding Detection */
    input rv32i_control_word ex_mem_out_ctrl,
    input rv32i_control_word id_ex_out_ctrl,
    input rv32i_control_word mem_wb_out_ctrl,
    
    /* Forwarding MUX Selection Signals */
    output idforwardamux::idforwardamux_sel_t id_forward_A_MUX_sel,
    output idforwardbmux::idforwardbmux_sel_t id_forward_B_MUX_sel,
    output exforwardamux::exforwardamux_sel_t ex_forward_A_MUX_sel,
    output exforwardbmux::exforwardbmux_sel_t ex_forward_B_MUX_sel,
    output wbmemforwardmux::wbmemforwardmux_sel_t wb_mem_forward_MUX_sel 
);



logic mem_ex_v_A;
logic mem_ex_v_B;
logic wb_ex_v_A;
logic wb_ex_v_B;


function void set_defaults();

    /* MEM-EX and WB-EX Forward Path */
    mem_ex_v_A = 1'b0;
    mem_ex_v_B = 1'b0;
    wb_ex_v_A = 1'b0;
    wb_ex_v_B = 1'b0;
    ex_forward_A_MUX_sel = exforwardamux::no_forward;
    ex_forward_B_MUX_sel = exforwardbmux::no_forward;

    /* WB-MEM Forward Path */
    wb_mem_forward_MUX_sel = wbmemforwardmux::no_forward;

endfunction



always_comb begin : MEM_EX_AND_WB_EX

    /* MEM-EX Forward Path */
    if(ex_mem_out_ctrl.load_regfile && (ex_mem_out_ctrl.rd_id == id_ex_out_ctrl.rs1_id) && ex_mem_out_ctrl.rd_id != 0)
    begin
        if(ex_mem_out_ctrl.opcode != op_load)
            mem_ex_v_A = 1'b1;
    end

    if(ex_mem_out_ctrl.load_regfile && (ex_mem_out_ctrl.rd_id == id_ex_out_ctrl.rs2_id) && ex_mem_out_ctrl.rd_id != 0)
    begin
        if(ex_mem_out_ctrl.opcode != op_load)
            mem_ex_v_B = 1'b1;
    end

    /* WB-EX Forward Path */
    if (mem_wb_out_ctrl.load_regfile && (mem_wb_out_ctrl.rd_id == id_ex_out_ctrl.rs1_id) && mem_wb_out_ctrl.rd_id != 0)
    begin 
        wb_ex_v_A  = 1'b1;
    end
    if (mem_wb_out_ctrl.load_regfile && (mem_wb_out_ctrl.rd_id == id_ex_out_ctrl.rs2_id) && mem_wb_out_ctrl.rd_id != 0)
    begin 
        wb_ex_v_B = 1'b1;
    end
    
    /* Priority Logic for MEM-EX vs WB-EX */
    if (mem_ex_v_A && wb_ex_v_A) 
        ex_forward_A_MUX_sel = exforwardamux::mem_alu_out;
    else if (mem_ex_v_A)
        ex_forward_A_MUX_sel = exforwardamux::mem_alu_out;
    else if(wb_ex_v_A)
        ex_forward_A_MUX_sel = exforwardamux::regfile_MUX_out;

    if (mem_ex_v_B && wb_ex_v_B) 
        ex_forward_B_MUX_sel = exforwardbmux::mem_alu_out;
    else if (mem_ex_v_B)
        ex_forward_B_MUX_sel = exforwardbmux::mem_alu_out;
    else if(wb_ex_v_B)
        ex_forward_B_MUX_sel = exforwardbmux::regfile_MUX_out;  

end


// always_comb : WB_MEM_FORWARD
// begin

//     if(mem_wb_out_ctrl.load_regfile && (mem_wb_out_ctrl.rd_id == ex_mem_out_ctrl.rs2_id) && mem_wb_out_ctrl.rd_id != 0)
//     begin
//         if(mem_wb_out_ctrl.opcode == op_load && ex_mem_out_ctrl.opcode == op_store)
//             wb_mem_forward_MUX_sel = wbmemforwardmux::regfile_MUX_out;

//     end

// end

// always_comb : MEM_ID_AND_EX_ID_FORWARD
// begin
//     /* MEM-ID Forward Path */
//     if (ex_mem_out_ctrl.load_regfile && (ex_mem_out_ctrl.rd_id == id_ex_in_ctrl.rs1_id) && ex_mem_out_ctrl.rd_id != 0) 
//     begin
//         if(ex_mem_out_ctrl.opcode == op_reg || ex_mem_out_ctrl.opcode == op_imm || ex_mem_out_ctrl.opcode == op_auipc)
//         begin
//             if(id_ex_in_ctrl.opcode == op_br || id_ex_in_ctrl.opcode == op_jalr || 
//             (id_ex_in_ctrl.opcode == op_reg && arith_funct3_t'(id_ex_in_ctrl.funct3) == slt) ||
//             (id_ex_in_ctrl.opcode == op_reg && arith_funct3_t'(id_ex_in_ctrl.funct3) == sltu) || 
//             (id_ex_in_ctrl.opcode == op_imm && arith_funct3_t'(id_ex_in_ctrl.funct3) == slt) ||
//             (id_ex_in_ctrl.opcode == op_imm && arith_funct3_t'(id_ex_in_ctrl.funct3) == slt)
//         end
//     end
    
// end

endmodule : forward_control_unit