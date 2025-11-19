module TOP_MODULE  #(
    parameter DATA_WIDTH = 16,
    parameter FRAC_WIDTH = 15,
    parameter TAPS_NUM = 138 
    )(
    input CLK,
    input RST,
    input signed [DATA_WIDTH-1:0] data_in,
    output signed [DATA_WIDTH-1:0] data_out
                                            );

    wire signed [DATA_WIDTH-1 : 0] Notch_in, FD_out;
    wire signed [DATA_WIDTH-1 : 0] internal_bridge;
    wire clkdiv;
    wire valid;
    
    //convert input from s16.15 to s16.14 
    assign Notch_in = FD_out >>> 1;

    Fractional_Decimator FR_D (
        .CLK(CLK),
        .RST(RST), //rst_n
        .x_n(data_in),
        .y_m(FD_out),
        .valid(valid)
    );

    clk_div CLK_DIV (
        .clk_in(CLK),
        .rst_n(RST),
        .clk_out(clkdiv)
    );

    Notch_Filter #(
        .width(DATA_WIDTH),
        .b0(16'h4000),
        .b1(16'h678e),
        .b2(16'h4000),
        .a1(16'h6473),
        .a2(16'h3c38)

    ) f1 (
        .CLK(clkdiv),
        .rst_n(RST),
        .x_n(Notch_in), // input S16.14
        .y_n(internal_bridge)  // output S16.15  
    );
    Notch_Filter #(
        .width(DATA_WIDTH),
        .b0(16'h4000),
        .b1(16'hc000),
        .b2(16'h4000),
        .a1(16'hc1ec),
        .a2(16'h3c38)

    ) f2 (
        .CLK(clkdiv),
        .rst_n(RST),
        .x_n(internal_bridge), // input S16.14
        .y_n(data_out)  // output S16.15  
    );



endmodule