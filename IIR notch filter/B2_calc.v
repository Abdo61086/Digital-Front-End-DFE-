module B2_calc #(
    parameter WIDTH = 32,
    parameter B2 = 16'h4000
)(
    input [WIDTH/2 - 1 : 0] operand_1,
    output reg [WIDTH-1 : 0 ] B2_out
);

always @ (*) begin
    B2_out = B2 * operand_1;
end

endmodule