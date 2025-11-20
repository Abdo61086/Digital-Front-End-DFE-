`timescale 1ns/1ps

module TOP_MODULE_TB;
    parameter CLK_PERIOD = 55.56; //18 Mhz

    parameter N_FD = 10000;
    parameter N_NOTCH = 6712;
    
    parameter DATA_WIDTH = 16;
    reg signed [DATA_WIDTH-1:0] input_vectors [0:N_FD-1];
    reg signed [DATA_WIDTH-1:0] FD_output_vectors [0:N_NOTCH-1];
    reg signed [DATA_WIDTH-1:0] Notch_output_vectors [0:N_NOTCH-1];
    reg signed [DATA_WIDTH-1:0] CIC_output_vectors [0:N_NOTCH-1];


    reg CLK_tb;
    reg RST_tb;
    reg filter_enable;
    reg signed [DATA_WIDTH-1:0] data_in_tb;
    wire signed [DATA_WIDTH-1:0] data_out_tb;
    reg [4:0] CIC_Decimation_Factor_tb;


    // DUT
    TOP_MODULE #(.DATA_WIDTH(DATA_WIDTH))
    DUT (
        .CLK(CLK_tb),
        .RST(RST_tb),
        .CIC_Decimation_Factor(CIC_Decimation_Factor_tb),
        .filter_enable(filter_enable),
        .data_in(data_in_tb),
        .data_out(data_out_tb)
    );

    // Clock generation
    always #(CLK_PERIOD/2.0) CLK_tb = ~CLK_tb;
    integer i;

    initial begin
            $readmemh("./Fractional_Decimator/filter_coeff.txt", DUT.FR_D.H);
            $readmemh("./Model_Output_Vectors/Input_Vectors.txt", input_vectors);
            CIC_Decimation_Factor_tb = 8;
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
            $readmemh("./Model_Output_Vectors/Fractional_Decimator_output.txt", FD_output_vectors);
            @(posedge DUT.valid)
            @(posedge DUT.valid)
            for (i_fd = 0; i_fd < N_NOTCH; i_fd = i_fd + 1) begin
                if(DUT.FD_out != FD_output_vectors[i_fd]) begin
                    $display("Error in FD output y[%0d] = %0h, y_expected = %0h  ", i_fd, DUT.FD_out, FD_output_vectors[i_fd]);
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
            $readmemh("./Model_Output_Vectors/Notch_Filter_Output.txt", Notch_output_vectors);
            repeat(4) @(negedge DUT.clkdiv);
            for (i_NOTCH = 0; i_NOTCH < N_NOTCH; i_NOTCH = i_NOTCH + 1) begin
                if(DUT.Notch_out != Notch_output_vectors[i_NOTCH]) begin
                    $display("Error in Notch output y[%0d] = %0h, y_expected = %0h  ", i_NOTCH, DUT.Notch_out, Notch_output_vectors[i_NOTCH]);
                    NOTCH_error = NOTCH_error + 1;
                end
                else 
                    NOTCH_correct = NOTCH_correct + 1;
                @(negedge DUT.clkdiv);
            end
            $display("Notch Status :: Num. of correct = %0d, Num. of errors = %0d", NOTCH_correct, NOTCH_error);
        end

        integer i_CIC, CIC_correct, CIC_error, D;

        initial begin
            CIC_correct = 0;
            CIC_error = 0;
            D = CIC_Decimation_Factor_tb;
            case (D)
                1  : $readmemh("./Model_Output_Vectors/CIC_Filter_Output_D_1.txt", CIC_output_vectors);
                2  : $readmemh("./Model_Output_Vectors/CIC_Filter_Output_D_2.txt", CIC_output_vectors);
                4  : $readmemh("./Model_Output_Vectors/CIC_Filter_Output_D_4.txt", CIC_output_vectors);
                8 : $readmemh("./Model_Output_Vectors/CIC_Filter_Output_D_8.txt", CIC_output_vectors);
                16 : $readmemh("./Model_Output_Vectors/CIC_Filter_Output_D_16.txt", CIC_output_vectors);

            endcase
           
            case (D)
                1 : repeat(7) @(negedge DUT.clkdiv);
                2 : repeat(4) @(posedge DUT.CIC_Filter.Sample_Flag);
                4 : repeat(3) @(posedge DUT.CIC_Filter.Sample_Flag);
                8, 16 : repeat(2) @(posedge DUT.CIC_Filter.Sample_Flag);
            endcase
            for (i_CIC = 0; i_CIC < N_NOTCH/D; i_CIC = i_CIC + 1) begin
                if(data_out_tb != CIC_output_vectors[i_CIC]) begin
                    $display("Error in CIC output y[%0d] = %0h, y_expected = %0h  ", i_CIC, data_out_tb, CIC_output_vectors[i_CIC]);
                    CIC_error = CIC_error + 1;
                end
                else 
                    CIC_correct = CIC_correct + 1;
                if(D == 1)
                    @(negedge DUT.clkdiv);
                else
                    @(posedge DUT.CIC_Filter.Sample_Flag);
            end
            $display("CIC Status :: Num. of correct = %0d, Num. of errors = %0d", CIC_correct, CIC_error);

            repeat(10) begin
                 if(D == 1)
                    @(negedge DUT.clkdiv);
                else
                    @(posedge DUT.CIC_Filter.Sample_Flag);
            end
            $stop;
        end
endmodule
