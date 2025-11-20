module clk_div(
    input      clk_in,
    input      rst_n,
    output reg clk_out
);

    reg [1:0] counter;

    always @(posedge clk_in, negedge rst_n) begin
        if (~rst_n) begin
            counter <= 1;
            clk_out <= 0;
        end 
        else begin
            if(counter == 2'b0) begin
                clk_out <= ~clk_out;
                counter <= counter + 1;
            end
            else if (counter == 2'b10) begin
                clk_out <= ~clk_out;
                counter <= 0;
            end 
            else 
                counter <= counter + 1;
        end
    end

endmodule
