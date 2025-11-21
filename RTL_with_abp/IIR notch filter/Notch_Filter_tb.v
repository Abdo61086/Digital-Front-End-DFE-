module Notch_Filter_tb();
    parameter N = 6712;
    parameter DATA_WIDTH = 16;

    reg signed [DATA_WIDTH-1:0] Samples [0:N-1];

    reg [DATA_WIDTH-1:0] output_vectors [0:N-1];

    reg CLK_tb;
    reg RST_tb;  //rst_n
    reg enable;
    reg signed [DATA_WIDTH-1:0] x_n_tb;
    wire signed [DATA_WIDTH-1:0] y_n_tb;
    wire signed [DATA_WIDTH-1:0] bridge;

Notch_Filter #(
        .width(DATA_WIDTH),
        .b0(16'h4000),
        .b1(16'h678e),
        .b2(16'h4000),
        .a1(16'h6473),
        .a2(16'h3c38)

    ) f1 (
        .CLK(CLK_tb),
        .rst_n(RST_tb),
        .enable(enable),
        .x_n(x_n_tb), // input S16.14
        .y_n(bridge)  // output S16.15  
    );
Notch_Filter #(
        .width(DATA_WIDTH),
        .b0(16'h4000),
        .b1(16'hc000),
        .b2(16'h4000),
        .a1(16'hc1ec),
        .a2(16'h3c38)

    ) f2 (
        .CLK(CLK_tb),
        .rst_n(RST_tb),
        .enable(enable),
        .x_n(bridge), // input S16.14
        .y_n(y_n_tb)  // output S16.15  
    );

    always #1 CLK_tb = ~CLK_tb;

    integer i, idx, correct, error;


    initial begin
        $readmemh("FD_output_vectors.txt", Samples);
        CLK_tb = 0;
        RST_tb = 0;
        x_n_tb = 0;
        enable = 1'b1;
        @(negedge CLK_tb)
        RST_tb = 1;
        @(posedge CLK_tb)
        for (i = 0; i < N; i = i + 1) begin
            //convert input from s16.15 to s16.14 
            x_n_tb = Samples[i] >>> 1;
            @(posedge CLK_tb);
        end
        x_n_tb = 0;
        $display("Num. of correct = %0d, Num. of errors = %0d", correct, error);
        $stop;
    end


    initial begin
        idx = 0;
        correct = 0;
        error = 0;
        $readmemh("Notch_output_vectors.txt", output_vectors);
        @(negedge CLK_tb)        
        @(negedge CLK_tb)
        forever begin
            if(y_n_tb != output_vectors[idx]) begin
                $display("Error in output y[%0d] = %0d, y_expected = %0d  ", idx, y_n_tb, output_vectors[idx]);
                error = error + 1;
            end
            else 
                correct = correct + 1;
            @(negedge CLK_tb)  idx = idx + 1;
        end
    end
endmodule