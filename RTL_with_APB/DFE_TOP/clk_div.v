module clk_div(
    input      clk_in,
    input      rst_n,
    input      EN,
    output     clk_out
);

    reg [1:0] counter;

    assign clk_out = (EN) ? (counter > 2'b01) : clk_in;

    always @(posedge clk_in, negedge rst_n) begin
        if (~rst_n) begin
            counter <= 0;
        end 
        else if (EN) begin
            if (counter == 2'b10) begin
                counter <= 0;
            end 
            else 
                counter <= counter + 1;
        end
        
    end

endmodule
