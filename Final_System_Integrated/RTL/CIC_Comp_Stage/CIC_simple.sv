//=============================================
//============ Simple CIC Decimator ===========
//=============================================
// 3-stage CIC with runtime-selectable decimation R=2^k, k in [0..4].
// Input valid gated; integrators run at input rate, combs at strobe.
// Fixed-point: in/out Q1.15 (16-bit). No overflow/status logic.
`timescale 1ns/1ns

module CIC_simple #(
  parameter int IN_W        = 16,
  parameter int FRAC        = 15,
  parameter int N           = 3,
  parameter int ACC_W       = 32,  // internal accumulator width
  parameter bit GAIN_COMP_EN= 1    // 1: apply >> (k*N) gain compensation, 0: disable (use full CIC gain)
) (
  input  logic                   clk,
  input  logic                   rst_n,       // active-low asynchronous reset
  input  logic                   clk_enable,
  input  logic                   in_valid,
  input  logic                   enable,
  input  logic        [2:0]      decim_sel, // 0..4 => R = 1<<decim_sel
  input  logic signed [IN_W-1:0] in_sample,
  
  output logic signed [IN_W-1:0] out_sample, // Q1.15 (truncated, unsaturated)
  output logic signed [ACC_W-1:0] out_wide,   // Wide, gain-compensated sample (for downstream FIR)
  output logic                   out_valid,
  output logic [7:0]             D_active
);
  //=============================================
  //============ Parameters and Vars ============
  //=============================================
  // Clamp selection and compute R
  logic [2:0] k;
  logic [7:0] R;
  always_comb begin
    k = (decim_sel > 3'd4) ? 3'd4 : decim_sel;
    R = 8'd1 << k; // 1,2,4,8,16
  end
  assign D_active = R;

  // Sign extend input to wider accumulator width
  logic signed [ACC_W-1:0] in_ext;
  always_comb begin
    in_ext = {{(ACC_W-IN_W){in_sample[IN_W-1]}}, in_sample};
  end

  // Integrators
  logic signed [ACC_W-1:0] int1, int2, int3;
  
  // Decimation counter
  logic [7:0] dec_cnt;
  logic       strobe;

  // Comb delay registers
  logic signed [ACC_W-1:0] c_z1, c_z2, c_z3;
  logic signed [ACC_W-1:0] c1, c2, c3;

  //=============================================
  //================= FF Logic ==================
  //=============================================
  // Integrator chain update
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      int1 <= '0; int2 <= '0; int3 <= '0;
    end else if (clk_enable && in_valid && enable) begin
      int1 <= int1 + in_ext;
      int2 <= int2 + int1;
      int3 <= int3 + int2;
    end
  end

  // Decimation strobe
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      dec_cnt <= 0; strobe <= 1'b0;
    end else if (clk_enable) begin
      if (~enable) begin
        dec_cnt <= 0; strobe <= 1'b0;
      end else if (in_valid) begin
        if (R == 8'd1) begin
          strobe <= 1'b1; dec_cnt <= 0;
        end else if (dec_cnt == R-1) begin
          strobe <= 1'b1; dec_cnt <= 0;
        end else begin
          strobe <= 1'b0; dec_cnt <= dec_cnt + 8'd1;
        end
      end else begin
        strobe <= 1'b0;
      end
    end
  end

  // Comb chain (M=1) operating on decimated samples
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      c_z1 <= '0; c_z2 <= '0; c_z3 <= '0; c1 <= '0; c2 <= '0; c3 <= '0;
    end else if (clk_enable && strobe && enable) begin
      c1   <= int3 - c_z1; c_z1 <= int3;
      c2   <= c1  - c_z2; c_z2 <= c1;
      c3   <= c2  - c_z3; c_z3 <= c2;
    end
  end

  // Output register: scale by CIC gain, then truncate/saturate to Q1.15.
  // CIC gain for M=1 is R^N = (2^k)^N = 2^(k*N). For R=1 (k=0) shift=0.
  // We apply an arithmetic right shift of (k*N) bits before truncation to compensate amplitude growth.
  logic signed [IN_W-1:0] c3_trunc;
  logic signed [ACC_W-1:0] c3_scaled;
  integer shift_amt;
  always_comb begin
  // If gain compensation disabled, do not right-shift; preserves full CIC amplitude (matches golden current model)
  shift_amt = GAIN_COMP_EN ? (k * N) : 0;
    if (shift_amt > 0) begin
      // Arithmetic shift for signed value
      c3_scaled = c3 >>> shift_amt;
    end else begin
      c3_scaled = c3;
    end
    c3_trunc = c3_scaled[IN_W-1:0];
  end

  // Register truncated and wide output without saturation; final saturation deferred downstream.
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      out_sample <= '0; out_wide <= '0; out_valid <= 1'b0;
    end else if (clk_enable) begin
      if (strobe && enable) begin
        out_sample <= c3_trunc;   // unsaturated truncated view
        out_wide   <= c3_scaled;  // full precision for FIR
        out_valid  <= 1'b1;
      end else begin
        out_valid <= 1'b0;
      end
    end
  end
endmodule
