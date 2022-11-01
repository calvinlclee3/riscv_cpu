/* DO NOT MODIFY. WILL BE OVERRIDDEN BY THE AUTOGRADER. */

module cacheline_adaptor
(
    input clk,
    input reset_n,

    // Port to LLC (Lowest Level Cache)
    input logic [255:0] line_i,
    output logic [255:0] line_o,
    input logic [31:0] address_i,
    input read_i,
    input write_i,
    output logic resp_o,

    // Port to memory
    input logic [63:0] burst_i,
    output logic [63:0] burst_o,
    output logic [31:0] address_o,
    output logic read_o,
    output logic write_o,
    input resp_i
);

    typedef enum bit [2:0] {IDLE, WAITR, WAITW, R, W, DONE} macro_t;
    struct packed {
        macro_t macro;
        logic [1:0] count;
    } state;
    localparam logic [1:0] maxcount = 2'b11;


    logic [255:0] linebuf;
    logic [31:0] addressbuf;
    assign line_o = linebuf;
    assign address_o = addressbuf;
    assign burst_o = linebuf[64 * state.count +: 64];
    assign read_o = ((state.macro == WAITR) || (state.macro == R));
    assign write_o = ((state.macro == WAITW) || (state.macro == W));
    assign resp_o = state.macro == DONE;
    enum bit [1:0] {READ_OP, WRITE_OP, NO_OP} op;
    assign op = read_i ? READ_OP : write_i ? WRITE_OP : NO_OP;

    always_ff @(posedge clk) begin
        if (~reset_n) begin
            state.macro <= IDLE;
        end
        else begin
            case (state.macro)
            IDLE: begin
                case (op)
                    NO_OP: ;
                    WRITE_OP: begin
                        state.macro <= WAITW;
                        linebuf <= line_i;
                        addressbuf <= address_i;
                        state.count <= 2'b00;
                    end
                    READ_OP: begin
                        state.macro <= WAITR;
                        addressbuf <= address_i;
                    end
                endcase
            end
            WAITR: begin
                if (resp_i) begin
                    state.macro <= R;
                    state.count <= 2'b01;
                    linebuf[63:0] <= burst_i;
                end
            end
            WAITW: begin
                if (resp_i) begin
                    state.macro <= W;
                    state.count <= 2'b01;
                end
            end
            R: begin
                if (state.count == maxcount) begin
                    state.macro <= DONE;
                end
                linebuf[64*state.count +: 64] <= burst_i;
                state.count <= state.count + 2'b01;
            end
            W: begin
                if (state.count == maxcount) begin
                    state.macro <= DONE;
                end
                state.count <= state.count + 2'b01;
            end
            DONE: begin
                state.macro <= IDLE;
            end
            endcase
        end
    end

endmodule : cacheline_adaptor