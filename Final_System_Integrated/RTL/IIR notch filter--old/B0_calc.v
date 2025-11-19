module B0_calc #(
    parameter WIDTH = 32
)(
    input signed [WIDTH-1 : 0] operand_1,
    input signed [15 : 0] B0,
    output reg signed [WIDTH*2 - 1 : 0] B0_out
);

always @ (*) begin
    B0_out = B0 * operand_1;
end

endmodule