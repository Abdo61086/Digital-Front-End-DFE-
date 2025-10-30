module B0_calc #(
    parameter WIDTH = 32,
    parameter B0 = 16'h4000
)(
    input [WIDTH/2 - 1 : 0] operand_1,
    output reg [WIDTH-1 : 0 ] B0_out
);

always @ (*) begin
    B0_out = B0 * operand_1;
end

endmodule