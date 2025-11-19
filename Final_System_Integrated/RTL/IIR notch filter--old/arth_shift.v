module arth_shift #(
    parameter WIDTH = 32
)(
    input signed [WIDTH*2 + 4 : 0] operand_1,
    output reg signed [WIDTH - 1 : 0] out
);

reg signed [WIDTH*2 + 4 : 0] w1;

always @ (*) begin
    w1 = operand_1 + 16'h2000;
    out = w1 >>> 14;
end

endmodule