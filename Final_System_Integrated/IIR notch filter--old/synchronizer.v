module synchronizer (
    input in,
    input clk,
    input enable,
    output reg out
);

reg reg1;
reg reg2;
reg flage;

always @(posedge clk) begin
    if (flage) begin
        reg1 <= in;
        reg2 <= reg1;
    end
end

always @ (*) begin
    if (enable) begin
        flage = 1'b1;
        out = reg2;
    end
    else begin
        flage = 1'b0;
        out = in;
    end
end

endmodule