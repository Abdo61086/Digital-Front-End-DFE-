module CIC_tb();
    parameter N = 6712;
    parameter DATA_WIDTH = 16;

    reg signed [DATA_WIDTH-1:0] Samples [0:N-1];

    reg [DATA_WIDTH-1:0] output_vectors [0:N-1];

    reg CLK_tb;
    reg RST_tb;  //rst_n
    reg signed [DATA_WIDTH-1:0] x_n_tb;
    wire signed [DATA_WIDTH-1:0] y_n_tb, CIC_in;
    reg [2:0] Decimation_Factor_tb;


    //convert input from s16.14 to s16.15 
    assign CIC_in = x_n_tb <<< 1;

    CIC DUT (
        .clk(CLK_tb),
        .rst_n(RST_tb),
        .EN(1'b1),
        .bypass(1'b0),
        .x_n(CIC_in),
        .Decimation_Factor(Decimation_Factor_tb),
        .y_n(y_n_tb)
    );

    always #1 CLK_tb = ~CLK_tb;

    integer i, idx, correct, error, D;


    initial begin
        $readmemh("./Model_Output_Vectors/Notch_Filter_Output.txt", Samples);
        CLK_tb = 0;
        RST_tb = 0;
        x_n_tb = 0;
        Decimation_Factor_tb = 3'b000;

        // Configure Decimation_Factor from script
        if ($value$plusargs("CIC_D=%b", Decimation_Factor_tb)) begin
            $display("Configuration: Running with Decimation Factor %0d", Decimation_Factor_tb);
        end else begin
            $display("Configuration: Defaulting to Decimation Factor 1");
        end
        @(negedge CLK_tb)
        RST_tb = 1;
        @(posedge CLK_tb)
        for (i = 0; i < N; i = i + 1) begin
            x_n_tb = Samples[i];
            @(posedge CLK_tb);
        end
        x_n_tb = 0;
        $display("CIC (D = %0d) Status Num. of correct = %0d, Num. of errors = %0d", D,  correct, error);
        $stop;
    end


    initial begin
        
        correct = 0;
        error = 0;
        D = 1 << Decimation_Factor_tb;
    
        case (D)
            1  : idx = 0;
            2  : idx = 1;
            4  : idx = 1;
            8  : idx = 5;
            16 : idx = 13;

        endcase
        $readmemh("./CIC_filter/CIC_Filter_Output_D.txt", output_vectors);

        repeat(4+D) @(negedge CLK_tb);        
        forever begin
            if(y_n_tb != output_vectors[idx]) begin
                $display("Error in output y[%0d] = %0h, y_expected = %0h  ", idx, y_n_tb, output_vectors[idx], $time);
                error = error + 1;
            end
            else 
                correct = correct + 1;
                  idx = idx + D;
            repeat(D) @(negedge CLK_tb);
        end
    end
endmodule