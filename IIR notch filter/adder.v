module adder #(
    parameter WIDTH = 32
)(
    input [WIDTH*2 - 1 : 0] operand_1,
    input [WIDTH*2 - 1 : 0] operand_2,
    input [WIDTH*2 - 1 : 0] operand_3,
    input [WIDTH*2 - 1 : 0] operand_4,
    input [WIDTH*2 - 1 : 0] operand_5,
    output reg [WIDTH*2 - 1 : 0] out
);

reg [WIDTH*2 - 1 : 0] w1;
reg [WIDTH*2 - 1 : 0] w2;

always @ (*) begin
    w1 = operand_1 + operand_2;
    w2 = operand_3 + operand_4;
    out = w1 + w2 + operand_5;
end

endmodule