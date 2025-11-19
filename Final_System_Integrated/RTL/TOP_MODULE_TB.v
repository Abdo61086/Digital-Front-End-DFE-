`timescale 1ns/1ps

module TOP_MODULE_TB;
    parameter CLK_PERIOD = 55.56; //18 Mhz

    parameter N_FD = 10000;
    parameter N_NOTCH = 6712;
    parameter DATA_WIDTH = 16;
    reg signed [DATA_WIDTH-1:0] input_vectors [0:N_FD-1];
    reg [DATA_WIDTH-1:0] FD_output_vectors [0:N_NOTCH-1];
    reg [DATA_WIDTH-1:0] Notch_output_vectors [0:N_NOTCH-1];


    reg CLK_tb;
    reg RST_tb;
    reg filter_enable,
    reg signed [DATA_WIDTH-1:0] data_in_tb;
    wire signed [DATA_WIDTH-1:0] data_out_tb;


    // DUT
    TOP_MODULE #(.DATA_WIDTH(DATA_WIDTH))
    DUT (
        .CLK(CLK_tb),
        .RST(RST_tb),
        .filter_enable(filter_enable),
        .data_in(data_in_tb),
        .data_out(data_out_tb)
    );

    // Clock generation
    always #(CLK_PERIOD/2.0) CLK_tb = ~CLK_tb;
    integer i;

    initial begin
            $readmemh("input_vectors.txt", input_vectors);
            CLK_tb = 0;
            RST_tb = 0;
            filter_enable = 1'b1;
            data_in_tb = 0;
            @(negedge CLK_tb)
            RST_tb = 1;
            @(posedge CLK_tb)
            for (i = 0; i < N_FD; i = i + 1) begin
                data_in_tb = input_vectors[i];
                @(posedge CLK_tb);
                @(posedge CLK_tb);
            end
            data_in_tb = 0;
            
        end


        integer i_fd, FD_correct, FD_error;
        initial begin
            FD_correct = 0;
            FD_error = 0;
            $readmemh("FD_output_vectors.txt", FD_output_vectors);
            @(posedge DUT.valid)
            @(posedge DUT.valid)
            for (i_fd = 0; i_fd < N_NOTCH; i_fd = i_fd + 1) begin
                if(DUT.FD_out != FD_output_vectors[i_fd]) begin
                    $display("Error in FD output y[%0d] = %0d, y_expected = %0d  ", i_fd, DUT.FD_out, FD_output_vectors[i_fd]);
                    FD_error = FD_error + 1;
                end
                else 
                    FD_correct = FD_correct + 1;
                @(posedge DUT.valid);
            end
            $display("FD Status :: Num. of correct = %0d, Num. of errors = %0d", FD_correct, FD_error);
        end

        integer i_NOTCH, NOTCH_correct, NOTCH_error;
        initial begin
            NOTCH_correct = 0;
            NOTCH_error = 0;
            $readmemh("Notch_output_vectors.txt", Notch_output_vectors);
            repeat(4) @(negedge DUT.clkdiv);
            for (i_NOTCH = 0; i_NOTCH < N_NOTCH; i_NOTCH = i_NOTCH + 1) begin
                if(data_out_tb != Notch_output_vectors[i_NOTCH]) begin
                    $display("Error in FD output y[%0d] = %0d, y_expected = %0d  ", i_NOTCH, data_out_tb, Notch_output_vectors[i_NOTCH]);
                    NOTCH_error = NOTCH_error + 1;
                end
                else 
                    NOTCH_correct = NOTCH_correct + 1;
                @(negedge DUT.clkdiv);
            end
            $display("Notch Status :: Num. of correct = %0d, Num. of errors = %0d", NOTCH_correct, NOTCH_error);
            $stop;
        end



endmodule
