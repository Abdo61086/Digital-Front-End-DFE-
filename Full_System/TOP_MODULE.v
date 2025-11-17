module TOP_MODULE  #(parameter DATA_WIDTH = 16,
                   parameter FRAC_WIDTH = 15,
                   parameter TAPS_NUM = 138 )(
                                              input CLK,
                                              input RST,
                                              input signed [DATA_WIDTH-1:0] x_n,
                                              output signed [DATA_WIDTH-1 : 0] data_out
                                            );

wire signed [DATA_WIDTH-1 : 0] data_in;
wire valid;
wire signed [DATA_WIDTH-1 : 0] internal_bridge;

    Fractional_Decimator FR_D (
        .CLK(CLK),
        .RST(RST), //rst_n
        .x_n(x_n),
        .y_m(data_in),
        .valid(valid)
    );

wire clkdiv;
clk_div CLK_DIV (
    .clk_in(CLK),
    .rst_n(RST),
    .clk_out(clkdiv)
);

top #(
    .WIDTH(DATA_WIDTH)
) top_for_2_pt_4 (
    .clk(clkdiv),
    .rst_n(RST),
    .A1(16'hC1EC),
    .A2(16'h3C38),
    .B0(16'h4000),
    .B1(16'hC000),
    .B2(16'h4000),
    .data_in(data_in),
    .data_out(internal_bridge)
);

top #(
    .WIDTH(DATA_WIDTH)
) top_for_5 (
    .clk(clkdiv),
    .rst_n(RST),
    .A1(16'h6473),
    .A2(16'h3C38),
    .B0(16'h4000),
    .B1(16'h678E),
    .B2(16'h4000),
    .data_in(internal_bridge),
    .data_out(data_out)
);



endmodule