package pcmux;
typedef enum bit [1:0] {
    pc_plus4  = 2'b00
    ,adder_out  = 2'b01
    ,adder_mod2 = 2'b10
} pcmux_sel_t;
endpackage

package marmux;
typedef enum bit {
    pc_out   = 1'b0
    ,alu_out = 1'b1
} marmux_sel_t;
endpackage

package cmpmux;
typedef enum bit {
    rs2_out = 1'b0
    ,imm    = 1'b1
} cmpmux_sel_t;
endpackage

package alumux;
typedef enum bit {
    rs1_out = 1'b0
    ,pc_out = 1'b1
} alumux1_sel_t;

typedef enum bit {
    imm      = 1'b0
    ,rs2_out = 1'b1
} alumux2_sel_t;
endpackage

package regfilemux;
typedef enum bit [2:0] {
    alu_out   = 3'b000
    ,br_en    = 3'b001
    ,imm      = 3'b010
    ,load     = 3'b011
    ,pc_plus4 = 3'b100
} regfilemux_sel_t;
endpackage

package targetaddressmux;
typedef enum bit {
    pc       = 1'b0
    ,rs1_out = 1'b1
} targetaddressmux_sel_t;
endpackage

