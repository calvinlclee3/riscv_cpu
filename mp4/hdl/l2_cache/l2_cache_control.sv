/* MODIFY. The cache controller. It is a state machine
that controls the behavior of the cache. */

module l2_cache_control 
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
    input logic way_2_hit,
    input logic way_3_hit,

    input logic v_array_0_dataout,
    input logic v_array_1_dataout,
    input logic v_array_2_dataout,
    input logic v_array_3_dataout,

    input logic d_array_0_dataout,
    input logic d_array_1_dataout,
    input logic d_array_2_dataout,
    input logic d_array_3_dataout,
    
    input logic [2:0] LRU_array_dataout,

    /* Control to Datapath */
    output logic v_array_0_load,
    output logic v_array_0_datain,
    output logic v_array_1_load,
    output logic v_array_1_datain,
    output logic v_array_2_load,
    output logic v_array_2_datain,
    output logic v_array_3_load,
    output logic v_array_3_datain,

    output logic d_array_0_load,
    output logic d_array_0_datain,
    output logic d_array_1_load,
    output logic d_array_1_datain,
    output logic d_array_2_load,
    output logic d_array_2_datain,
    output logic d_array_3_load,
    output logic d_array_3_datain,

    output logic tag_array_0_load,
    output logic tag_array_1_load,
    output logic tag_array_2_load,
    output logic tag_array_3_load,

    output logic LRU_array_load,
    output logic [2:0] LRU_array_datain,

    output logic memory_buffer_register_load,

    output dataarraymux_sel_t write_en_0_MUX_sel,
    output dataarraymux_sel_t write_en_1_MUX_sel,
    output dataarraymux_sel_t write_en_2_MUX_sel,
    output dataarraymux_sel_t write_en_3_MUX_sel,
    output dataarraymux_sel_t data_array_0_datain_MUX_sel,
    output dataarraymux_sel_t data_array_1_datain_MUX_sel,
    output dataarraymux_sel_t data_array_2_datain_MUX_sel,
    output dataarraymux_sel_t data_array_3_datain_MUX_sel,

    output logic [1:0] dataout_MUX_sel,

    output pmemaddressmux_sel_t pmem_address_MUX_sel

);

logic count_l2missFSM;
logic overflow_l2missFSM;
logic [31:0] num_l2missFSM;

perf_counter l2missFSM (
.clk(clk),
.rst(rst),
.count(count_l2missFSM),
.overflow(overflow_l2missFSM),
.out(num_l2missFSM)
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
    v_array_2_load = 1'b0;
    v_array_2_datain = 1'b0;
    v_array_3_load = 1'b0;
    v_array_3_datain = 1'b0;

    d_array_0_load = 1'b0;
    d_array_0_datain = 1'b0;
    d_array_1_load = 1'b0;
    d_array_1_datain = 1'b0;
    d_array_2_load = 1'b0;
    d_array_2_datain = 1'b0;
    d_array_3_load = 1'b0;
    d_array_3_datain = 1'b0;

    tag_array_0_load = 1'b0;
    tag_array_1_load = 1'b0;
    tag_array_2_load = 1'b0;
    tag_array_3_load = 1'b0;

    LRU_array_load = 1'b0;
    LRU_array_datain = 3'b000;

    memory_buffer_register_load  = 1'b0;

    write_en_0_MUX_sel = no_write; 
    write_en_1_MUX_sel = no_write;
    write_en_2_MUX_sel = no_write; 
    write_en_3_MUX_sel = no_write;
    data_array_0_datain_MUX_sel = no_write;
    data_array_1_datain_MUX_sel = no_write;
    data_array_2_datain_MUX_sel = no_write;
    data_array_3_datain_MUX_sel = no_write;

    dataout_MUX_sel = 2'b00;

    pmem_address_MUX_sel = cache_read_mem;
    count_l2missFSM = 1'b0;

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
                    LRU_array_datain = {1'b0, 1'b0, LRU_array_dataout[0]};
                else if (way_1_hit)
                    LRU_array_datain = {1'b0, 1'b1, LRU_array_dataout[0]};
                else if (way_2_hit)
                    LRU_array_datain = {1'b1, LRU_array_dataout[1], 1'b0};
                else if (way_3_hit)
                    LRU_array_datain = {1'b1, LRU_array_dataout[1], 1'b1};  
            end
            else count_l2missFSM = 1'b1;
            if(mem_read)
            begin
                if(way_0_hit == 1'b1 && way_1_hit == 1'b0 && way_2_hit == 1'b0 && way_3_hit == 1'b0)
                    dataout_MUX_sel = 2'b00;
                else if(way_0_hit == 1'b0 && way_1_hit == 1'b1 && way_2_hit == 1'b0 && way_3_hit == 1'b0)
                    dataout_MUX_sel = 2'b01;
                else if(way_0_hit == 1'b0 && way_1_hit == 1'b0 && way_2_hit == 1'b1 && way_3_hit == 1'b0)
                    dataout_MUX_sel = 2'b10;
                else if (way_0_hit == 1'b0 && way_1_hit == 1'b0 && way_2_hit == 1'b0 && way_3_hit == 1'b1)
                    dataout_MUX_sel = 2'b11;
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
                else if(hit && way_2_hit)
                begin
                    write_en_2_MUX_sel = cpu_write_cache;
                    data_array_2_datain_MUX_sel = cpu_write_cache;
                    d_array_2_load = 1'b1;
                    d_array_2_datain = 1'b1;
                end
                else if(hit && way_3_hit)
                begin
                    write_en_3_MUX_sel = cpu_write_cache;
                    data_array_3_datain_MUX_sel = cpu_write_cache;
                    d_array_3_load = 1'b1;
                    d_array_3_datain = 1'b1;
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
            else if(v_array_2_dataout == 1'b0)
            begin
                tag_array_2_load = 1'b1;
                v_array_2_load = 1'b1;
                v_array_2_datain = 1'b1;
                d_array_2_load = 1'b1;
                d_array_2_datain = 1'b0;
                write_en_2_MUX_sel = mem_write_cache;
                data_array_2_datain_MUX_sel = mem_write_cache;
            end
            else if(v_array_3_dataout == 1'b0)
            begin
                tag_array_3_load = 1'b1;
                v_array_3_load = 1'b1;
                v_array_3_datain = 1'b1;
                d_array_3_load = 1'b1;
                d_array_3_datain = 1'b0;
                write_en_3_MUX_sel = mem_write_cache;
                data_array_3_datain_MUX_sel = mem_write_cache;
            end
            else
            begin
                if(LRU_array_dataout[2] == 1'b0)
                begin
                    if(LRU_array_dataout[0] == 1'b0)
                    begin
                        // Alloc way 3
                        tag_array_3_load = 1'b1;
                        v_array_3_load = 1'b1;
                        v_array_3_datain = 1'b1;
                        d_array_3_load = 1'b1;
                        d_array_3_datain = 1'b0;
                        write_en_3_MUX_sel = mem_write_cache;
                        data_array_3_datain_MUX_sel = mem_write_cache;
                    end
                    else
                    begin
                        // Alloc way 2
                        tag_array_2_load = 1'b1;
                        v_array_2_load = 1'b1;
                        v_array_2_datain = 1'b1;
                        d_array_2_load = 1'b1;
                        d_array_2_datain = 1'b0;
                        write_en_2_MUX_sel = mem_write_cache;
                        data_array_2_datain_MUX_sel = mem_write_cache;
                    end
                end
                else
                begin
                    if(LRU_array_dataout[1] == 1'b0)
                    begin
                        // Alloc way 1
                        tag_array_1_load = 1'b1;
                        v_array_1_load = 1'b1;
                        v_array_1_datain = 1'b1;
                        d_array_1_load = 1'b1;
                        d_array_1_datain = 1'b0;
                        write_en_1_MUX_sel = mem_write_cache;
                        data_array_1_datain_MUX_sel = mem_write_cache;
                    end
                    else
                    begin
                        // Alloc way 0
                        tag_array_0_load = 1'b1;
                        v_array_0_load = 1'b1;
                        v_array_0_datain = 1'b1;
                        d_array_0_load = 1'b1;
                        d_array_0_datain = 1'b0;
                        write_en_0_MUX_sel = mem_write_cache;
                        data_array_0_datain_MUX_sel = mem_write_cache;
                    end  
                end
            end
        end
        WRITE_BACK:
        begin
            if(LRU_array_dataout[2] == 1'b0)
            begin
                if(LRU_array_dataout[0] == 1'b0)
                begin
                    // Alloc way 3
                    pmem_write = 1'b1;
                    dataout_MUX_sel = 2'b11;
                    pmem_address_MUX_sel = cache_write_mem;
                    v_array_3_load = 1'b1;
                    v_array_3_datain = 1'b0;
                end
                else
                begin
                    // Alloc way 2
                    pmem_write = 1'b1;
                    dataout_MUX_sel = 2'b10;
                    pmem_address_MUX_sel = cache_write_mem;
                    v_array_2_load = 1'b1;
                    v_array_2_datain = 1'b0;
                end
            end
            else
            begin
                if(LRU_array_dataout[1] == 1'b0)
                begin
                    // Alloc way 1
                    pmem_write = 1'b1;
                    dataout_MUX_sel = 2'b01;
                    pmem_address_MUX_sel = cache_write_mem;
                    v_array_1_load = 1'b1;
                    v_array_1_datain = 1'b0;
                end
                else
                begin
                    // Alloc way 0
                    pmem_write = 1'b1;
                    dataout_MUX_sel = 2'b00;
                    pmem_address_MUX_sel = cache_write_mem;
                    v_array_0_load = 1'b1;
                    v_array_0_datain = 1'b0;
                end  
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
            else if(v_array_0_dataout == 1'b0 || v_array_1_dataout == 1'b0 || v_array_2_dataout == 1'b0 || v_array_3_dataout == 1'b0)
            begin
                next_state = NO_WB_1;
            end
            else
            begin
                if(LRU_array_dataout[2] == 1'b0)
                begin
                    if(LRU_array_dataout[0] == 1'b0)
                    begin
                        // Alloc way 3
                        if(d_array_3_dataout == 1'b0)
                            next_state = NO_WB_1;
                        else
                            next_state = WRITE_BACK;
                    end
                    else
                    begin
                        // Alloc way 2
                        if(d_array_2_dataout == 1'b0)
                            next_state = NO_WB_1;
                        else
                            next_state = WRITE_BACK;
                    end
                end
                else
                begin
                    if(LRU_array_dataout[1] == 1'b0)
                    begin
                        // Alloc way 1
                        if(d_array_1_dataout == 1'b0)
                            next_state = NO_WB_1;
                        else
                            next_state = WRITE_BACK;
                    end
                    else
                    begin
                        // Alloc way 0
                        if(d_array_0_dataout == 1'b0)
                            next_state = NO_WB_1;
                        else
                            next_state = WRITE_BACK;
                    end  
                end

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

endmodule : l2_cache_control
