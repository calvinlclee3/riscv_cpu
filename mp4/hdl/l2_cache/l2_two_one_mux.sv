module l2_two_one_mux
(
input logic selection, 
input logic A, 
input logic B,
output logic dataout
);

always_comb begin
    dataout = 1'b0;

    case(selection)
    1'b0: dataout = A;
    1'b1: dataout = B;
    endcase

end


endmodule
