`timescale 1ns/1ps

module TOP_MODULE_TB;
    parameter CLK_PERIOD = 55.56; //18 Mhz

    parameter N_FD = 10000;
    parameter N_NOTCH = 6712;
    
    parameter DATA_WIDTH = 16;
    parameter ABP_ADDR_WIDTH = 4;
    parameter ABP_DATA_WIDTH = 32;
    parameter DFE_DATA_WIDTH = 16;
    // Model Vectors
    reg signed [DATA_WIDTH-1:0] input_vectors [0:N_FD-1];
    reg signed [DATA_WIDTH-1:0] FD_output_vectors [0:N_NOTCH-1];
    reg signed [DATA_WIDTH-1:0] Notch_output_vectors [0:N_NOTCH-1];
    reg signed [DATA_WIDTH-1:0] CIC_output_vectors [0:N_NOTCH-1];


    reg CLK_tb;
    reg RST_tb;

    reg signed [DATA_WIDTH-1:0] data_in_tb;
    wire signed [DATA_WIDTH-1:0] data_out_tb;
    reg [4:0] CIC_Decimation_Factor_tb;



    reg PSEL_tb;
    reg PENABLE_tb;
    reg PWRITE_tb;

    reg  [ABP_ADDR_WIDTH-1:0] PADDR_tb;
    reg  [ABP_DATA_WIDTH-1:0] PWDATA_tb;
    wire [ABP_DATA_WIDTH-1:0] PRDATA_tb;

    

    top_module #(
    .ABP_ADDR_WIDTH(ABP_ADDR_WIDTH),
    .ABP_DATA_WIDTH(ABP_DATA_WIDTH),
    .DFE_DATA_WIDTH(DFE_DATA_WIDTH)
    ) DUT(
                            
    // APB Signals
    .PCLK(CLK_tb),
    .PRESETn(RST_tb),
    .PSEL(PSEL_tb),
    .PENABLE(PENABLE_tb),
    .PWRITE(PWRITE_tb),
    .PADDR(PADDR_tb),
    .PWDATA(PWDATA_tb),
    .PRDATA(PRDATA_tb),

    //dfe signals
    .input_data(data_in_tb),
    .output_data(data_out_tb)

    );



    // Clock generation
    always #(CLK_PERIOD/2.0) CLK_tb = ~CLK_tb;
    integer i;

    initial begin
            $readmemh("./Fractional_Decimator/filter_coeff.txt", DUT.u_dft_top.FR_D.H);
            $readmemh("./Model_Output_Vectors/Input_Vectors.txt", input_vectors);

            CIC_Decimation_Factor_tb = 3'b100; // 16
            CLK_tb = 0;
            RST_tb = 0;
            data_in_tb = 0;
            @(negedge CLK_tb);
            RST_tb = 1;
            @(posedge CLK_tb);
            
            ABP_Write(4'h0, {CIC_Decimation_Factor_tb, 9'b0000_11111});

            ABP_Write(4'h2, {16'h4000, 16'h678e}); // B0_1 B1_1
            ABP_Write(4'h3, {16'h4000, 16'h6502}); // B2_1 A1_1

            ABP_Write(4'h4, {16'h3ce4, 16'h4000});  // A2_1 B0_2

            ABP_Write(4'h5, {16'h4000, 16'h4000});  // B1_2 B2_2
            ABP_Write(4'h6, {16'h3e6d, 16'h3ce4});  // A1_2 A2_2


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
            repeat(2) @(DUT.u_dft_top.FD_out);

            for (i_fd = 1; i_fd < N_NOTCH; i_fd = i_fd + 1) begin
                if(DUT.u_dft_top.FD_out != FD_output_vectors[i_fd]) begin
                    $display("Error in FD output y[%0d] = %0h, y_expected = %0h  ", i_fd, DUT.u_dft_top.FD_out, FD_output_vectors[i_fd]);
                    FD_error = FD_error + 1;
                end
                else 
                    FD_correct = FD_correct + 1;
                @(posedge DUT.u_dft_top.valid);
            end
            $display("FD Status :: Num. of correct = %0d, Num. of errors = %0d", FD_correct, FD_error);
        end

        integer i_NOTCH, NOTCH_correct, NOTCH_error;
        initial begin
            NOTCH_correct = 0;
            NOTCH_error = 0;
            $readmemh("./Model_Output_Vectors/Notch_Filter_Output.txt", Notch_output_vectors);
            repeat(2) @(DUT.u_dft_top.Notch_out);
            @(negedge DUT.u_dft_top.clkdiv); //skip undetected 1st zero
            
            for (i_NOTCH = 1; i_NOTCH < N_NOTCH; i_NOTCH = i_NOTCH + 1) begin
                if(DUT.u_dft_top.Notch_out != Notch_output_vectors[i_NOTCH]) begin
                    $display("Error in Notch output y[%0d] = %0h, y_expected = %0h  ", i_NOTCH, DUT.u_dft_top.Notch_out, Notch_output_vectors[i_NOTCH]);
                    NOTCH_error = NOTCH_error + 1;
                end
                else 
                    NOTCH_correct = NOTCH_correct + 1;
                @(negedge DUT.u_dft_top.clkdiv);
            end
            $display("Notch Status :: Num. of correct = %0d, Num. of errors = %0d", NOTCH_correct, NOTCH_error);
        end

        integer i_CIC, CIC_correct, CIC_error, D;

        initial begin
            CIC_correct = 0;
            CIC_error = 0;
            D = 1 << CIC_Decimation_Factor_tb;
            case (D)
                1  : i_CIC = 1;
                2  : i_CIC = 2;
                4  : i_CIC = 4;
                8  : i_CIC = 5;
                16 : i_CIC = 8;

            endcase
            $readmemh("./Model_Output_Vectors/CIC_Filter_Output_D.txt", CIC_output_vectors);

            repeat(2) @(data_out_tb);
            if(D == 1) begin
                @(negedge DUT.u_dft_top.clkdiv); //skip undetected 1st zero
            end
            else begin
                @(posedge DUT.u_dft_top.CIC_Filter.Sample_Flag);
            end
            for ( ;i_CIC < N_NOTCH; i_CIC = i_CIC + D) begin
                if(data_out_tb != CIC_output_vectors[i_CIC]) begin
                    $display("Error in CIC output y[%0d] = %0h, y_expected = %0h  ", i_CIC, data_out_tb, CIC_output_vectors[i_CIC], $time);
                    CIC_error = CIC_error + 1;
                end
                else 
                    CIC_correct = CIC_correct + 1;
                if(D == 1)
                    @(negedge DUT.u_dft_top.clkdiv);
                else
                    @(posedge DUT.u_dft_top.CIC_Filter.Sample_Flag);
            end
            $display("CIC Status :: Num. of correct = %0d, Num. of errors = %0d", CIC_correct, CIC_error);

            repeat(10) begin
                 if(D == 1)
                    @(negedge DUT.u_dft_top.clkdiv);
                else
                    @(posedge DUT.u_dft_top.CIC_Filter.Sample_Flag);
            end
            $stop;
        end

    task ABP_Write;
        input [ABP_ADDR_WIDTH-1:0] ADDR;
        input [ABP_DATA_WIDTH-1:0] DATA;
        begin
            PSEL_tb   = 1'b1;
            PWRITE_tb = 1'b1;

            PADDR_tb  = ADDR;
            PWDATA_tb = DATA;
            @(posedge CLK_tb);
            PENABLE_tb = 1'b1;
            @(posedge CLK_tb);
            PSEL_tb   = 1'b0;
            PENABLE_tb = 1'b0;
        end
    endtask


    task ABP_Read;
        begin
            PSEL_tb   = 1'b1;
            PWRITE_tb = 1'b0;
            @(posedge CLK_tb);
            PENABLE_tb = 1'b1;
            @(posedge CLK_tb);
            PSEL_tb   = 1'b0;
            PENABLE_tb = 1'b0;
        end
    endtask

endmodule
