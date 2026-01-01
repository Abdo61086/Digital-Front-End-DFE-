module dfe_top  #(
    parameter DATA_WIDTH = 16,
    parameter FRAC_WIDTH = 15,
    parameter TAPS_NUM = 138 
    )(
    input CLK,
    input RST,
    input [5*DATA_WIDTH-1:0] filter_coeff_notch_1, 
    input [5*DATA_WIDTH-1:0] filter_coeff_notch_2,

    input [2:0] CIC_Decimation_Factor,
    input signed [DATA_WIDTH-1:0] data_in,
    output signed [DATA_WIDTH-1:0] data_out,

    input FD_EN,
    input FD_bypass,

    input NOTCH_EN_1,
    input NOTCH_bypass_1,

    input NOTCH_EN_2,
    input NOTCH_bypass_2,

    input CIC_EN,
    input CIC_bypass,

    input CLKDIV_EN 
    
 );



    wire signed [DATA_WIDTH-1 : 0]  FD_out, Notch_in, Notch_out, CIC_in;
    wire signed [DATA_WIDTH-1 : 0] internal_bridge;
    wire clkdiv;
    wire valid;
    

    //convert input from s16.15 to s16.14 
    assign Notch_in = FD_out >>> 1;

    //convert input from s16.14 to s16.15 
    assign CIC_in = Notch_out <<< 1;
    

    Fractional_Decimator FR_D (
        .CLK(CLK),
        .RST(RST), //rst_n
        .x_n(data_in),
        .EN(FD_EN),
        .bypass(FD_bypass),
        .y_m(FD_out),
        .valid(valid)
    );

    clk_div CLK_DIV (
        .clk_in(CLK),
        .rst_n(RST),
        .EN(CLKDIV_EN),
        .clk_out(clkdiv)
    );

    Notch_Filter #(
        .width(DATA_WIDTH)
        // .b0(16'h4000),
        // .b1(16'h678e),
        // .b2(16'h4000),
        // .a1(16'h6473),
        // .a2(16'h3c38)

    ) Notch_1 (
        .CLK(clkdiv),
        .rst_n(RST),
        .EN(NOTCH_EN_1),
        .bypass(NOTCH_bypass_1),
        .filter_coeff(filter_coeff_notch_1),
        .x_n(Notch_in), // input S16.14
        .y_n(internal_bridge)  // output S16.15  
    );
    Notch_Filter #(
        .width(DATA_WIDTH)
        // .b0(16'h4000),
        // .b1(16'hc000),
        // .b2(16'h4000),
        // .a1(16'hc1ec),
        // .a2(16'h3c38)

    ) Notch_2 (
        .CLK(clkdiv),
        .rst_n(RST),
        .EN(NOTCH_EN_2),
        .bypass(NOTCH_bypass_2),
        .filter_coeff(filter_coeff_notch_2),
        .x_n(internal_bridge), // input S16.14
        .y_n(Notch_out)  // output S16.15  
    );

    CIC CIC_Filter (
        .clk(clkdiv),
        .rst_n(RST),
        .EN(CIC_EN),
        .bypass(CIC_bypass),
        .x_n(CIC_in),
        .Decimation_Factor(CIC_Decimation_Factor), // Decimation Factor D = 2^k, k in [0..4]
        .y_n(data_out)
    );
endmodule