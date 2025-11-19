module B2_calc #(
    parameter WIDTH = 32
)(
    input signed [WIDTH-1 : 0] operand_1,
    input signed [15 : 0] B2,
    output reg signed [WIDTH*2 - 1 : 0] B2_out
);

always @ (*) begin
    B2_out = B2 * operand_1;
end

endmodule