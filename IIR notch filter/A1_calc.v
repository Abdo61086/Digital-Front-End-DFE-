module A1_calc #(
    parameter WIDTH = 32,
    parameter A1 = 16'h6473
)(
    input [WIDTH-1 : 0] operand_1,
    output reg [WIDTH-1 : 0 ] A1_out
);

always @ (*) begin
    A1_out = A1 * operand_1;
end

endmodule