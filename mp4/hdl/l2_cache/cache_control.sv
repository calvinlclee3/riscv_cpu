/* MODIFY. The cache controller. It is a state machine
that controls the behavior of the cache. */

module cache_control 
import rv32i_types::*;
import cache_mux_types::*;
(

    input clk,
    input rst,


    /* CPU memory signals */
    input   logic           mem_read,
    input   logic           mem_write,
    output  logic           mem_resp,

    /* Physical memory signals */
    input   logic           pmem_resp,
    output  logic           pmem_read,
    output  logic           pmem_write,

    /* Datapath to Control */
    input logic hit,
    input logic way_0_hit,
    input logic way_1_hit,

    input logic v_array_0_dataout,
    input logic v_array_1_dataout,

    input logic d_array_0_dataout,
    input logic d_array_1_dataout,
    
    input logic LRU_array_dataout,

    /* Control to Datapath */
    output logic v_array_0_load,
    output logic v_array_0_datain,
    output logic v_array_1_load,
    output logic v_array_1_datain,

    output logic d_array_0_load,
    output logic d_array_0_datain,
    output logic d_array_1_load,
    output logic d_array_1_datain,

    output logic tag_array_0_load,
    output logic tag_array_1_load,

    output logic LRU_array_load,
    output logic LRU_array_datain,

    output logic memory_buffer_register_load,

    output dataarraymux_sel_t write_en_0_MUX_sel,
    output dataarraymux_sel_t write_en_1_MUX_sel,
    output dataarraymux_sel_t data_array_0_datain_MUX_sel,
    output dataarraymux_sel_t data_array_1_datain_MUX_sel,

    output logic dataout_MUX_sel,

    output pmemaddressmux_sel_t pmem_address_MUX_sel

);

enum int unsigned {
    /* List of states */
    DEFAULT = 0, READ_WRITE = 1, NO_WB_1 = 2, NO_WB_2 = 3, 
    WRITE_BACK = 4

} state, next_state;

function void set_defaults();

    /* CPU memory signals */
    mem_resp = 1'b0;


    /* Physical memory signals */
    pmem_read = 1'b0;
    pmem_write = 1'b0;

    /* Control to Datapath */
    v_array_0_load = 1'b0;
    v_array_0_datain = 1'b0;
    v_array_1_load = 1'b0;
    v_array_1_datain = 1'b0;

    d_array_0_load = 1'b0;
    d_array_0_datain = 1'b0;
    d_array_1_load = 1'b0;
    d_array_1_datain = 1'b0;

    tag_array_0_load = 1'b0;
    tag_array_1_load = 1'b0;

    LRU_array_load = 1'b0;
    LRU_array_datain = 1'b0;

    memory_buffer_register_load  = 1'b0;

    write_en_0_MUX_sel = no_write; 
    write_en_1_MUX_sel = no_write;
    data_array_0_datain_MUX_sel = no_write;
    data_array_1_datain_MUX_sel = no_write;

    dataout_MUX_sel = 1'b0;

    pmem_address_MUX_sel = cache_read_mem;

endfunction

always_comb
begin : state_actions

    /* Default output assignments */
    set_defaults();

    /* Actions for each state */
    case(state)
        DEFAULT:;
        READ_WRITE:
        begin
            mem_resp = hit;
            if(hit)
            begin
                LRU_array_load = 1'b1;
                if(way_0_hit)
                    LRU_array_datain = 1'b1;
                else
                    LRU_array_datain = 1'b0;
            end
            if(mem_read)
            begin
                if(way_0_hit == 1'b1 && way_1_hit == 1'b0)
                    dataout_MUX_sel = 1'b0;
                else
                    dataout_MUX_sel = 1'b1;
            end
            else if(mem_write)
            begin
                if(hit && way_0_hit)
                begin
                    write_en_0_MUX_sel = cpu_write_cache;
                    data_array_0_datain_MUX_sel = cpu_write_cache;
                    d_array_0_load = 1'b1;
                    d_array_0_datain = 1'b1;
                end
                else if(hit && way_1_hit)
                begin
                    write_en_1_MUX_sel = cpu_write_cache;
                    data_array_1_datain_MUX_sel = cpu_write_cache;
                    d_array_1_load = 1'b1;
                    d_array_1_datain = 1'b1;
                end
            end
        end
        NO_WB_1:
        begin
            pmem_read = 1'b1;
            pmem_address_MUX_sel = cache_read_mem;
            memory_buffer_register_load = 1'b1;
        end
        NO_WB_2:
        begin
            if(v_array_0_dataout == 1'b0)
            begin
                tag_array_0_load = 1'b1;
                v_array_0_load = 1'b1;
                v_array_0_datain = 1'b1;
                d_array_0_load = 1'b1;
                d_array_0_datain = 1'b0;
                write_en_0_MUX_sel = mem_write_cache;
                data_array_0_datain_MUX_sel = mem_write_cache;
            end
            else if(v_array_1_dataout == 1'b0)
            begin
                tag_array_1_load = 1'b1;
                v_array_1_load = 1'b1;
                v_array_1_datain = 1'b1;
                d_array_1_load = 1'b1;
                d_array_1_datain = 1'b0;
                write_en_1_MUX_sel = mem_write_cache;
                data_array_1_datain_MUX_sel = mem_write_cache;
            end
            else if(LRU_array_dataout == 1'b0)
            begin
                tag_array_0_load = 1'b1;
                v_array_0_load = 1'b1;
                v_array_0_datain = 1'b1;
                d_array_0_load = 1'b1;
                d_array_0_datain = 1'b0;
                write_en_0_MUX_sel = mem_write_cache;
                data_array_0_datain_MUX_sel = mem_write_cache;
            end
            else if(LRU_array_dataout == 1'b1)
            begin
                tag_array_1_load = 1'b1;
                v_array_1_load = 1'b1;
                v_array_1_datain = 1'b1;
                d_array_1_load = 1'b1;
                d_array_1_datain = 1'b0;
                write_en_1_MUX_sel = mem_write_cache;
                data_array_1_datain_MUX_sel = mem_write_cache;
            end
        end
        WRITE_BACK:
        begin
            if(LRU_array_dataout == 1'b0)
            begin
                pmem_write = 1'b1;
                dataout_MUX_sel = 1'b0;
                pmem_address_MUX_sel = cache_write_mem;
                v_array_0_load = 1'b1;
                v_array_0_datain = 1'b0;
            end
            else
            begin
                pmem_write = 1'b1;
                dataout_MUX_sel = 1'b1;
                pmem_address_MUX_sel = cache_write_mem;
                v_array_1_load = 1'b1;
                v_array_1_datain = 1'b0;
            end
        end
    endcase
end

always_comb
begin : next_state_logic
    /* Next state information and conditions (if any)
     * for transitioning between states */

    next_state = state;

    case(state)
        DEFAULT:
        begin
            if(mem_read == 1'b1 || mem_write == 1'b1)
                next_state = READ_WRITE;
        end
        READ_WRITE:
        begin
            if(hit == 1'b1)
            begin
                next_state = DEFAULT;
            end
            else if(v_array_0_dataout == 1'b0 || v_array_1_dataout == 1'b0)
            begin
                next_state = NO_WB_1;
            end
            else if(LRU_array_dataout == 1'b0 && d_array_0_dataout == 1'b0)
            begin
                next_state = NO_WB_1;
            end
            else if(LRU_array_dataout == 1'b1 && d_array_1_dataout == 1'b0)
            begin
                next_state = NO_WB_1;
            end
            else
            begin
                next_state = WRITE_BACK;
            end
        end
        NO_WB_1:
        begin
            if(pmem_resp == 1'b1)
            begin
                next_state = NO_WB_2;
            end
        end
        NO_WB_2:
        begin
            next_state = READ_WRITE;
        end
        WRITE_BACK:
        begin
            if(pmem_resp == 1'b1)
            begin
                next_state = NO_WB_1;
            end
        end
    endcase
end

always_ff @(posedge clk)
begin: next_state_assignment
    /* Assignment of next state on clock edge */
    if (rst)
    begin
        state <= DEFAULT;
    end
    else
    begin
        state <= next_state;
    end
end

endmodule : cache_control
