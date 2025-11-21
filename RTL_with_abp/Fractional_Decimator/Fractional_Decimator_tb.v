module Fractional_Decimator_tb();
    parameter N = 10000;
    parameter TAPS_NUM = 138;
    parameter DATA_WIDTH = 16;

    reg [DATA_WIDTH-1:0] Samples [0:N-1];

    reg [DATA_WIDTH-1:0] output_vectors [0:6712-1];

    reg CLK_tb;
    reg RST_tb;  //rst_n
    reg signed [DATA_WIDTH-1:0] x_n_tb;
    wire signed [DATA_WIDTH-1:0] y_m_tb;
    wire valid_tb;

    Fractional_Decimator DUT (
        .CLK(CLK_tb),
        .RST(RST_tb), //rst_n
        .x_n(x_n_tb),
        .y_m(y_m_tb),
        .EN(1'b1),
        .bypass(1'b0),
        .valid(valid_tb)
    );

    always #1 CLK_tb = ~CLK_tb;

    integer i, idx, correct, error;


    initial begin
        $readmemh("./Fractional_Decimator/filter_coeff.txt", DUT.H);
        $readmemh("./Model_Output_Vectors/Input_Vectors.txt", Samples);
        
        CLK_tb = 0;
        RST_tb = 0;
        x_n_tb = 0;
        @(negedge CLK_tb)
        RST_tb = 1;
        @(posedge CLK_tb)
        for (i = 0; i < N; i = i + 1) begin
            x_n_tb = Samples[i];
            @(posedge CLK_tb);
            @(posedge CLK_tb);
        end
        x_n_tb = 0;
        repeat(TAPS_NUM)  @(posedge CLK_tb);
        $display("FD Status Num. of correct = %0d, Num. of errors = %0d", correct, error);
        $stop;
    end


    initial begin
        idx = 0;
        correct = 0;
        error = 0;
        $readmemh("./Model_Output_Vectors/Fractional_Decimator_output.txt", output_vectors);
        @(posedge valid_tb)
        @(posedge valid_tb)
        forever begin
            if(y_m_tb != output_vectors[idx]) begin
                $display("Error in output y[%0d] = %0d, y_expected = %0d  ", idx, y_m_tb, output_vectors[idx]);
                error = error + 1;
            end
            else 
                correct = correct + 1;
            @(posedge valid_tb)  idx = idx + 1;
        end
    end
endmodule