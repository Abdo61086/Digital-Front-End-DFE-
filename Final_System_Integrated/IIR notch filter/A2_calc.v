module A2_calc #(
    parameter WIDTH = 32
)(
    input signed [WIDTH-1 : 0] operand_1,
    input signed [15 : 0] A2,
    output reg signed [WIDTH*2 - 1 : 0] A2_out
);

always @ (*) begin
    A2_out = A2 * operand_1;
end

endmodule