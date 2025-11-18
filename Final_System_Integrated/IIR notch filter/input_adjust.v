module input_adjust #(
    parameter WIDTH = 32
)(
    input signed [WIDTH-1 : 0] in,
    output reg signed [WIDTH-1 : 0] out
);

reg signed [WIDTH-1 : 0] w1;

always @ (*) begin
    w1 = in + 1'b1;
    out = w1 >>> 1;
end

endmodule