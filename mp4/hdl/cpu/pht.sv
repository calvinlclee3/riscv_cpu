module pht #(
    parameter s_index = 4
)
(
    input logic clk,
    input logic rst,
    input logic increment,
    input logic decrement,
    input logic [s_index-1:0] rindex,
    input logic [s_index-1:0] windex,
    output logic out
);

localparam num_sets = 2**s_index;

logic [1:0] data [num_sets-1:0];
logic [1:0] in;

always_comb
begin
    in = data[windex];
    if(increment)
    begin
        if(data[windex] != 2'b11)
            in = data[windex] + 2'b01;
    end
    else if(decrement)
    begin
        if(data[windex] != 2'b00)
            in = data[windex] - 2'b01;
    end
end

always_ff @(posedge clk)
begin
    if (rst)
    begin
        for (int i = 0; i < num_sets; ++i)
            data[i] <= 2'b10;
    end
    else
    begin
        data[windex] <= in;
    end
end

always_comb
begin
    if((rindex == windex) && (decrement || increment))
        // transparent
        out = in[1];
    else
        out = data[rindex][1];

end

endmodule : pht
