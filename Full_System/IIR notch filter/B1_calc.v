module B1_calc #(
    parameter WIDTH = 32
)(
    input signed [WIDTH-1 : 0] operand_1,
    input signed [15 : 0] B1,
    output reg signed [WIDTH*2 - 1 : 0] B1_out
);

always @ (*) begin
    B1_out = B1 * operand_1;
end

endmodule