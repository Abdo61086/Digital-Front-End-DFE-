//=============================================
//============ Clean CIC Decimator ============
//=============================================
// 3-stage CIC with runtime-selectable decimation R=2^k, k in [0..4]
// Inputs are sample-valid gated; integrators run at input rate, combs at output strobe.
// Fixed-point: input Q1.15 (16-bit), internal/output Q1.15 (28-bit) with saturation.
`timescale 1 ns / 1 ns

module CIC #(
  parameter int IN_W = 16,
  parameter int OUT_W = 28,
  parameter int FRAC  = 15,  // fractional bits
  parameter int N     = 3     // number of integrator/comb stages
) (
  input  logic                   clk,
  input  logic                   reset,         // active-high synchronous reset
  input  logic                   clk_enable,    // clock enable
  input  logic                   in_valid,      // input sample valid
  input  logic                   in_enable,     // when 0, pass-through (no valid)
  input  logic                   sync_reset,    // soft reset of datapath
  input  logic signed [IN_W-1:0] in_sample,     // sfixIN_W_En(FRAC)
  input  logic        [2:0]      decim_sel,     // 0..4 => R = 1<<decim_sel

  output logic signed [OUT_W-1:0] out_sample,   // sfixOUT_W_En(FRAC)
  output logic                    out_valid,    // strobe at decimated rate
  output logic        [7:0]       D_active,     // actual decimation factor (1,2,4,8,16)
  output logic        [5:0]       ovf_flags     // [2:0]=int1..3, [5:3]=comb1..3 (sticky)
);

  //=============================================
  //============ Parameters and Vars ============
  //=============================================
  // Sign-extend input to OUT_W
  logic signed [OUT_W-1:0] in_ext;
  
  // Compute R and clamp selection
  logic [2:0] k;
  logic [7:0] R;

  // Integrator chain (N=3)
  logic signed [OUT_W-1:0] int1, int2, int3;
  logic                    ovf_int1_sticky, ovf_int2_sticky, ovf_int3_sticky;
  // temp wide adders
  logic signed [OUT_W:0]   sum1, sum2, sum3;
  logic                    en_data;

  // Downsampler counter
  logic [7:0] dec_cnt;
  logic       strobe;

  // Capture decimated output from integrator 3
  logic signed [OUT_W-1:0] decim_sample;

  // Comb chain at output strobe domain (M=1, N stages)
  logic signed [OUT_W-1:0] c_z1, c_z2, c_z3;
  logic signed [OUT_W-1:0] c1, c2, c3;
  logic                    ovf_c1_sticky, ovf_c2_sticky, ovf_c3_sticky;
  logic signed [OUT_W:0]   diff1, diff2, diff3;

  //=============================================
  //============ Combinational Logic ============
  //=============================================
  always_comb begin
    in_ext = {{(OUT_W-IN_W){in_sample[IN_W-1]}}, in_sample};
  end

  always_comb begin
    k = (decim_sel > 3'd4) ? 3'd4 : decim_sel;
    R = 8'd1 << k;  // 1,2,4,8,16
  end
  assign D_active = R;

  assign en_data = clk_enable & in_valid & in_enable & ~sync_reset;

  //=============================================
  //================= FF Logic ==================
  //=============================================
  always_ff @(posedge clk) begin
    if (reset) begin
      int1 <= '0; int2 <= '0; int3 <= '0;
      ovf_int1_sticky <= 1'b0; ovf_int2_sticky <= 1'b0; ovf_int3_sticky <= 1'b0;
    end else if (clk_enable) begin
      if (sync_reset) begin
        int1 <= '0; int2 <= '0; int3 <= '0;
        ovf_int1_sticky <= 1'b0; ovf_int2_sticky <= 1'b0; ovf_int3_sticky <= 1'b0;
      end else if (in_enable & in_valid) begin
        // int1 accumulation with overflow detect
        sum1 = $signed({int1[OUT_W-1], int1}) + $signed({in_ext[OUT_W-1], in_ext});
        if (sum1[OUT_W] != sum1[OUT_W-1]) begin
          ovf_int1_sticky <= 1'b1;
          int1 <= sum1[OUT_W] ? {1'b1, {OUT_W-1{1'b0}}} : {1'b0, {OUT_W-1{1'b1}}};
        end else begin
          int1 <= sum1[OUT_W-1:0];
        end

        // int2 accumulation
        sum2 = $signed({int2[OUT_W-1], int2}) + $signed({int1[OUT_W-1], int1});
        if (sum2[OUT_W] != sum2[OUT_W-1]) begin
          ovf_int2_sticky <= 1'b1;
          int2 <= sum2[OUT_W] ? {1'b1, {OUT_W-1{1'b0}}} : {1'b0, {OUT_W-1{1'b1}}};
        end else begin
          int2 <= sum2[OUT_W-1:0];
        end

        // int3 accumulation
        sum3 = $signed({int3[OUT_W-1], int3}) + $signed({int2[OUT_W-1], int2});
        if (sum3[OUT_W] != sum3[OUT_W-1]) begin
          ovf_int3_sticky <= 1'b1;
          int3 <= sum3[OUT_W] ? {1'b1, {OUT_W-1{1'b0}}} : {1'b0, {OUT_W-1{1'b1}}};
        end else begin
          int3 <= sum3[OUT_W-1:0];
        end
      end
    end
  end

  always_ff @(posedge clk) begin
    if (reset) begin
      dec_cnt <= 8'd0; strobe <= 1'b0;
    end else if (clk_enable) begin
      if (sync_reset | ~in_enable) begin
        dec_cnt <= 8'd0; strobe <= 1'b0;
      end else if (in_valid) begin
        if (R == 8'd1) begin
          strobe <= 1'b1;         // every sample
          dec_cnt <= 8'd0;
        end else if (dec_cnt == (R - 1)) begin
          strobe <= 1'b1;
          dec_cnt <= 8'd0;
        end else begin
          strobe <= 1'b0;
          dec_cnt <= dec_cnt + 8'd1;
        end
      end else begin
        strobe <= 1'b0;
      end
    end
  end

  always_ff @(posedge clk) begin
    if (reset) begin
      decim_sample <= '0;
    end else if (clk_enable) begin
      if (sync_reset) begin
        decim_sample <= '0;
      end else if (strobe) begin
        decim_sample <= int3;
      end
    end
  end

  always_ff @(posedge clk) begin
    if (reset) begin
      c_z1 <= '0; c_z2 <= '0; c_z3 <= '0;
      c1   <= '0; c2   <= '0; c3   <= '0;
      ovf_c1_sticky   <= 1'b0; ovf_c2_sticky   <= 1'b0; ovf_c3_sticky   <= 1'b0;
    end else if (clk_enable) begin
      if (sync_reset) begin
        c_z1 <= '0; c_z2 <= '0; c_z3 <= '0;
        c1   <= '0; c2   <= '0; c3   <= '0;
        ovf_c1_sticky   <= 1'b0; ovf_c2_sticky   <= 1'b0; ovf_c3_sticky   <= 1'b0;
      end else if (strobe) begin
        // comb1: decim_sample - c_z1 with saturation/flag
        diff1 = $signed({decim_sample[OUT_W-1], decim_sample}) - $signed({c_z1[OUT_W-1], c_z1});
        if (diff1[OUT_W] != diff1[OUT_W-1]) begin
          ovf_c1_sticky <= 1'b1;
          c1 <= diff1[OUT_W] ? {1'b1, {OUT_W-1{1'b0}}} : {1'b0, {OUT_W-1{1'b1}}};
        end else begin
          c1 <= diff1[OUT_W-1:0];
        end
        c_z1 <= decim_sample;

        // comb2: c1 - c_z2
        diff2 = $signed({c1[OUT_W-1], c1}) - $signed({c_z2[OUT_W-1], c_z2});
        if (diff2[OUT_W] != diff2[OUT_W-1]) begin
          ovf_c2_sticky <= 1'b1;
          c2 <= diff2[OUT_W] ? {1'b1, {OUT_W-1{1'b0}}} : {1'b0, {OUT_W-1{1'b1}}};
        end else begin
          c2 <= diff2[OUT_W-1:0];
        end
        c_z2 <= c1;

        // comb3: c2 - c_z3
        diff3 = $signed({c2[OUT_W-1], c2}) - $signed({c_z3[OUT_W-1], c_z3});
        if (diff3[OUT_W] != diff3[OUT_W-1]) begin
          ovf_c3_sticky <= 1'b1;
          c3 <= diff3[OUT_W] ? {1'b1, {OUT_W-1{1'b0}}} : {1'b0, {OUT_W-1{1'b1}}};
        end else begin
          c3 <= diff3[OUT_W-1:0];
        end
        c_z3 <= c2;
      end
    end
  end

  //=============================================
  //================= Outputs ===================
  //=============================================
  assign out_sample = (in_enable) ? c3 : in_ext;  // pass-through when disabled
  assign out_valid  = (in_enable) ? strobe : 1'b0;
  assign ovf_flags  = {ovf_c3_sticky, ovf_c2_sticky, ovf_c1_sticky, ovf_int3_sticky, ovf_int2_sticky, ovf_int1_sticky};

endmodule
