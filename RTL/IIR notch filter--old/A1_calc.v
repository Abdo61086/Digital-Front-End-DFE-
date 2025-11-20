module A1_calc #(
    parameter WIDTH = 32
)(
    input signed [WIDTH-1 : 0] operand_1,
    input signed [15 : 0] A1,
    output reg signed [WIDTH*2 - 1 : 0] A1_out
);

always @ (*) begin
    A1_out = A1 * operand_1;
end

endmodule