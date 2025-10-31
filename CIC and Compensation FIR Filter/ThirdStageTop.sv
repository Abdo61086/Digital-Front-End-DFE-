// Clean top for CIC third stage with optional compensation FIR
// Matches original top-level ports for drop-in replacement.
`timescale 1 ns / 1 ns

module CIC_ThirdStageTop (
  input  logic                 clk,
  input  logic                 reset,             // active-high
  input  logic                 clk_enable,
  input  logic signed [15:0]  x_in,              // sfix16_En15
  input  logic                 x_valid,
  input  logic                 ctrl_enable,
  input  logic                 ctrl_reset,
  input  logic        [7:0]   ctrl_decim_sel,    // 0..4 => D=2^k
  input  logic                 ctrl_comp_enable,
  output logic                 ce_out,
  output logic signed [27:0]  y_out,             // sfix28_En15
  output logic                 y_valid,
  output logic        [7:0]   status_D_active,
  output logic        [7:0]   status_overflow,
  output logic                 status_ready
);

  // Clamp decimation selector
  logic [2:0] k;
  always_comb begin
    k = (ctrl_decim_sel[2:0] > 3'd4) ? 3'd4 : ctrl_decim_sel[2:0];
  end

  // CIC decimator
  logic signed [27:0] cic_out;
  logic cic_vld;
  logic [7:0] D_act;
  logic [5:0] cic_ovf;
  CIC u_cic (
    .clk(clk), .reset(reset), .clk_enable(clk_enable),
    .in_valid(x_valid), .in_enable(ctrl_enable), .sync_reset(ctrl_reset),
    .in_sample(x_in), .decim_sel(k),
    .out_sample(cic_out), .out_valid(cic_vld), .D_active(D_act),
    .ovf_flags(cic_ovf)
  );

  // Compensation FIR at CIC output rate
  logic signed [27:0] fir_out;
  logic fir_vld;
  logic fir_ovf;
  CompensationFIR u_comp (
    .clk(clk), .reset(reset), .clk_enable(clk_enable),
    .in_valid(cic_vld), .comp_enable(ctrl_comp_enable), .decim_sel(k),
    .in_sample(cic_out), .out_sample(fir_out), .out_valid(fir_vld),
    .sync_reset(ctrl_reset), .ovf_flag(fir_ovf)
  );

  // Output select: when disabled, pass-through is handled in CIC (in_enable=0)
  // If compensation enabled and D>1, FIR asserts valid; otherwise cic_vld passes through.
  logic use_fir;
  assign use_fir = ctrl_comp_enable & (D_act != 8'd1);

  assign y_out   = use_fir ? fir_out  : cic_out;
  assign y_valid = use_fir ? fir_vld  : cic_vld;

  // Status
  assign status_D_active = D_act;
  // Overflow mapping: [5:0]=CIC {comb3,comb2,comb1,int3,int2,int1}; [6]=FIR; [7]=0
  assign status_overflow = {1'b0, fir_ovf, cic_ovf};
  assign status_ready    = 1'b1;
  assign ce_out          = clk_enable;

endmodule
