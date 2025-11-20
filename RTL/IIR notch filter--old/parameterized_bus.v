module parameterized_bus #(
    parameter WIDTH = 32
)(
    input clk,
    input rst_n,
    input signed [WIDTH-1 : 0] data_in,
    output reg signed [WIDTH-1 : 0] data_out
);

always @ (posedge clk or negedge rst_n) begin
    if(!rst_n)
        data_out <= {WIDTH{1'b0}};
    else
        data_out <= data_in;
end

endmodule