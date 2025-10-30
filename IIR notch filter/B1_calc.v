module B1_calc #(
    parameter WIDTH = 32,
    parameter B1 = 16'h678E
)(
    input [WIDTH/2 - 1 : 0] operand_1,
    output reg [WIDTH-1 : 0 ] B1_out
);

always @ (*) begin
    B1_out = B1 * operand_1;
end

endmodule