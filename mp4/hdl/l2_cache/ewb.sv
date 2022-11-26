module ewb
import rv32i_types::*;
#(
    width = 256,
    index = 6, 
    tag = 24, 
    cap = 64
)
(
    input logic clk,
    input logic rst, 

    // valid-ready input protocol
    input logic [width-1:0] data_i,
    input logic [31:0] addr_i,
    input logic valid_i,
    output logic full_o,

    input logic tag_check,
    input logic [26:0] tag_i,
    output logic hit_o,
    output logic [width-1:0] read_o,

    // valid-yumi output protocol
    output logic empty_o,
    output logic [width-1:0] data_o,
    input logic yumi_i
);

/******************************** Declarations *******************************/
// Need memory to hold queued data
logic [width-1:0] queue_data [cap];
logic [31:0] queue_addr [cap];

// Pointers which point to the read and write ends of the queue
logic [index-1:0] read_ptr, write_ptr, read_ptr_next, write_ptr_next;
logic [index:0] queue_counter;

assign write_ptr_next = (write_ptr == cap-1)? '0: write_ptr+1;
assign read_ptr_next = (read_ptr == cap-1)? '0: read_ptr+1;

// Helper logic
logic enqueue, dequeue;


assign full_o = (queue_counter == cap)? 1'b1: 1'b0;
assign empty_o = (queue_counter == '0)? 1'b1: 1'b0;
assign enqueue = (valid_i == 1'b1) && (full_o == 1'b0);
assign dequeue = (yumi_i == 1'b1) && (empty_o == 1'b0);

/*************************** Non-Blocking Assignments ************************/
always_ff @(posedge clk, posedge rst) begin
    if (rst) begin
        read_ptr  <= '0;
        write_ptr <= '0;
        queue_counter <= '0;
    end
    else begin
        case ({enqueue, dequeue})
            2'b01: begin : dequeue_case
                read_ptr <= read_ptr_next;
                queue_counter <= queue_counter-1;
            end
            2'b10: begin : enqueue_case
                queue_data[write_ptr] <= data_i;
                queue_addr[write_ptr] <= addr_i;
                write_ptr <= write_ptr_next;
                queue_counter <= queue_counter+1;
            end
            default:;
        endcase
    end

end

always_comb begin
    hit_o = 1'b0;
    read_o = '0;
    if (tag_check == 1'b1) begin
        for (int i = 0; i < queue_counter; ++i) begin
            if (queue_addr[(i+read_ptr)%cap][31:5] == tag_i) begin
                hit_o = 1'b1;
                read_o = queue_data[(i+read_ptr)%cap];
            end
        end
    end
end

assign data_o = queue_data[read_ptr];


endmodule : ewb
