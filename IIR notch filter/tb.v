module tb;

parameter WIDTH = 16;
parameter A1 = 16'h6473;
parameter A2 = 16'h3C38;
parameter B0 = 16'h4000;
parameter B1 = 16'h678E;
parameter B2 = 16'h4000;

reg clk;
reg rst_n;
reg [WIDTH-1 : 0] data_in;
wire [WIDTH*2 - 1 : 0] data_out_;

integer i;
integer fd;

reg [15:0] data_i [6711:0];
reg [WIDTH*2 - 1 : 0] data_o [6711:0];

top #(.WIDTH(WIDTH), .B0(B0), .B1(B1), .B2(B2), .A1(A1), .A2(A2)) DUT (
    .clk(clk),
    .rst_n(rst_n),
    .data_in(data_in),
    .data_out(data_out_)
);

initial begin
    clk = 0;
    forever
    #10 clk = ~clk;
end

initial begin
    $readmemh("data_in.hex", data_i);
    fd = $fopen("data_o.hex", "w");
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
    for(i = 0; i < 6712; i = i + 1) begin
        data_in = data_i[i];
        @(negedge clk);
        data_o[i] = data_out_;
    end
    for(i = 0; i < 6712; i = i + 1) begin
        $fdisplay(fd, "%04h", data_o[i]);
    end
    $fclose(fd);
    $display("Done writing out.hex");
    $stop;
end
endmodule