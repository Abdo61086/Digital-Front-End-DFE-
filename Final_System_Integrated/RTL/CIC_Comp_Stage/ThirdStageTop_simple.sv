`timescale 1ns/1ns

module ThirdStageTop_simple (
  input  logic               clk,
  input  logic               rst_n,
  input  logic [2:0]         decim_sel,
  input  logic signed [15:0] in_sample,
  output logic signed [15:0] out_sample
);

  logic signed [15:0] cic_out_sample;
  logic                cic_out_valid;
  logic signed [31:0]  cic_out_wide;
  logic [7:0]          d_active;

  CIC_simple #(
    .IN_W(16),
    .FRAC(15),
    .GAIN_COMP_EN(0)
  ) cic_inst (
    .clk(clk),
    .rst_n(rst_n),
    .clk_enable(1'b1),
    .in_valid(1'b1),
    .enable(1'b1),
    .decim_sel(decim_sel),
    .in_sample(in_sample),
    .out_sample(cic_out_sample),
    .out_wide(cic_out_wide),
    .out_valid(cic_out_valid),
    .D_active(d_active)
  );

  CompensationFIR_simple #(
    .W(16),
    .FRAC(15)
  ) fir_inst (
    .clk(clk),
    .rst_n(rst_n),
    .clk_enable(1'b1),
    .in_valid(cic_out_valid),
    .enable(1'b1),
    .decim_sel(decim_sel),
    .in_sample(cic_out_sample),
    .out_sample(out_sample),
    .out_valid()
  );

endmodule
