module A2_calc #(
    parameter WIDTH = 32,
    parameter A2 = 16'h3C38
)(
    input [WIDTH-1 : 0] operand_1,
    output reg [WIDTH-1 : 0 ] A2_out
);

always @ (*) begin
    A2_out = A2 * operand_1;
end

endmodule