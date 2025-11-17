`timescale 1ns/1ps

module TOP_MODULE_TB;
    parameter CLK_PERIOD = 55.56; //18 Mhz

    parameter N = 10000;
    parameter TAPS_NUM = 138;
    parameter DATA_WIDTH = 16;

    reg CLK_tb;
    reg RST_tb;
    reg signed [DATA_WIDTH-1:0] x_n_tb;
    wire signed [DATA_WIDTH-1:0] data_out_tb;

    reg signed [DATA_WIDTH-1:0] Samples [0:N-1];
    reg signed [DATA_WIDTH-1:0] data_o [0:6719];
    integer fd, i, j;

    // DUT
    TOP_MODULE #(.DATA_WIDTH(DATA_WIDTH),  .TAPS_NUM(TAPS_NUM))
    DUT (
        .CLK(CLK_tb),
        .RST(RST_tb),
        .x_n(x_n_tb),
        .data_out(data_out_tb)
    );

    // Clock generation
    initial CLK_tb = 0;
    always #(CLK_PERIOD/2.0) CLK_tb = ~CLK_tb;

    initial begin
        // Load input samples
        $readmemh("input_vectors.txt", Samples);

        // Open file for output
        fd = $fopen("data_out.hex", "w");

        // Reset initialization
        RST_tb = 0;
        x_n_tb = 0;
        @(posedge CLK_tb);
        RST_tb = 1;


        // Feed input samples
        for (i = 0; i < N; i = i + 1) begin
            x_n_tb = Samples[i];
            @(posedge CLK_tb);
            @(posedge CLK_tb); // pipeline delay
        end

        x_n_tb = 0;
    end
        
initial
 begin
        @(negedge CLK_tb);
        @(negedge CLK_tb);
        @(negedge CLK_tb);
        @(negedge CLK_tb);
        @(negedge CLK_tb);

        // Capture outputs
        for (j = 0; j < N; j = j + 1) begin
            data_o[j] = data_out_tb;
            @(negedge CLK_tb);
             @(negedge CLK_tb);
            @(negedge CLK_tb);
        end

        // Write outputs to file
        for (j = 0; j < N; j = j + 1) begin
            $fdisplay(fd, "%04h", data_o[j]);
        end
       // Wait for filter tail to flush
        repeat(TAPS_NUM) @(posedge CLK_tb);
        $fclose(fd);
        $display("Done writing data_out.hex");
        $stop;
    end
endmodule
