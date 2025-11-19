module adder #(
    parameter WIDTH = 32
)(
    input signed [WIDTH*2 -1 : 0] operand_1,
    input signed [WIDTH*2 -1 : 0] operand_2,
    input signed [WIDTH*2 -1 : 0] operand_3,
    input signed [WIDTH*2 -1 : 0] operand_4,
    input signed [WIDTH*2 -1 : 0] operand_5,
    output reg signed [WIDTH*2 + 4 : 0] out
);

reg signed [WIDTH*2 + 4 : 0] w1;
reg signed [WIDTH*2 + 4 : 0] w2;

always @ (*) begin
    w1 = operand_1 + operand_2;
    w2 = operand_3 - operand_5;
    out = w1 + w2 - operand_4;
end

endmodule