module top_filter ();

parameter WIDTH = 16;
// parameter A1_1 = 17'h0C8E5;
// parameter A2_1 = 17'h0786F;
// parameter B0_1 = 17'h08000;
// parameter B1_1 = 17'h0CF1B;
// parameter B2_1 = 17'h07FFF;

// parameter A1_2 = 17'h183D7;
// parameter A2_2 = 17'h0786F;
// parameter B0_2 = 17'h08000;
// parameter B1_2 = 17'h18000;
// parameter B2_2 = 17'h07FFF;

reg clk;
reg rst_n;
reg signed [WIDTH-1 : 0] data_in;
wire signed [WIDTH-1 : 0] data_out_;
wire signed [WIDTH-1 : 0] internal_bridge;

integer i;
integer fd;

reg signed [15:0] data_i [6720:0];
reg signed [WIDTH-1 : 0] data_o [6720:0];

top #(
    .WIDTH(WIDTH)
) top_for_2_pt_4 (
    .clk(clk),
    .rst_n(rst_n),
    .A1(16'hC1EC),
    .A2(16'h3C38),
    .B0(16'h4000),
    .B1(16'hC000),
    .B2(16'h4000),
    .data_in(data_in),
    .data_out(internal_bridge)
);

top #(
    .WIDTH(WIDTH)
) top_for_5 (
    .clk(clk),
    .rst_n(rst_n),
    .A1(16'h6473),
    .A2(16'h3C38),
    .B0(16'h4000),
    .B1(16'h678E),
    .B2(16'h4000),
    .data_in(internal_bridge),
    .data_out(data_out_)
);

initial begin
    clk = 0;
    forever
    #10 clk = ~clk;
end

initial begin
    $readmemh("data_in.hex", data_i);
    fd = $fopen("data_out.hex", "w");
    if (fd == 0) begin
        $display("ERROR: Cannot open file!");
        $stop;
    end
end

initial begin
    rst_n = 1'b0;
    
    repeat (10)
        @(negedge clk);
    
    rst_n = 1'b1;
    @(negedge clk);
    @(negedge clk);

    for(i = 0; i < 6720; i = i + 1) begin
        data_in = data_i[i];
        @(negedge clk);
        data_o[i] = data_out_;
    end
    for(i = 0; i < 6720; i = i + 1) begin
        $fdisplay(fd, "%04h", data_o[i]);
    end
    $fclose(fd);
    $display("Done writing out.hex");
    $stop;
end

endmodule