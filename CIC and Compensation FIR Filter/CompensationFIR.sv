//=============================================
//========= Clean Compensation FIR (DFE) ======
//=============================================
// Per-D coefficient sets (D=2,4,8,16) selected by decim_sel.
// Operates at CIC output rate. If comp_enable=0 or D=1, bypasses input.
// Fixed-point: in/out Q1.15 (28-bit). Internals use 56-bit products, rounded to 28-bit.
`timescale 1 ns / 1 ns

module CompensationFIR #(
  parameter int W    = 28,
  parameter int FRAC = 15
) (
  input  logic                 clk,
  input  logic                 reset,        // active-high synchronous reset
  input  logic                 clk_enable,
  input  logic                 in_valid,
  input  logic                 comp_enable,
  input  logic        [2:0]    decim_sel,    // 0..4 => D = 2^decim_sel
  input  logic signed [W-1:0]  in_sample,    // sfixW_En(FRAC)
  output logic signed [W-1:0]  out_sample,   // sfixW_En(FRAC)
  output logic                 out_valid,
  input  logic                 sync_reset,   // optional clear for sticky flags
  output logic                 ovf_flag      // sticky saturation flag
);

  //=============================================
  //============ Parameters and Vars ============
  //=============================================
  // Coefficient sets from generated FilterCoef*.sv (Q1.27 in 28-bit signed)
  localparam int MAX_TAPS = 22;

  typedef logic signed [W-1:0]   sample_t;
  typedef logic signed [27:0]    coeff_t;     // Q1.27
  typedef logic signed [55:0]    prod_t;      // W(28)+C(28)
  typedef logic signed [61:0]    acc_t;       // allow headroom for 22 taps

  // D=2 (21 taps) from FilterCoef.sv
  localparam int NTAPS_D2 = 21;
  localparam coeff_t COEF_D2 [0:NTAPS_D2-1] = '{
    28'sb1111111111101111011000101101,
    28'sb0000000101011011010101110100,
    28'sb0000001001011110001101010100,
    28'sb1111111000101110101100011100,
    28'sb1111110000000100111010100101,
    28'sb0000010100011000001010101010,
    28'sb0000011001110011100000011101,
    28'sb1111001100000101010100110010,
    28'sb1111010110001010110110101100,
    28'sb0010100101000111101011100001,
    28'sb0100110100011011011100010111,
    28'sb0010100101000111101011100001,
    28'sb1111010110001010110110101100,
    28'sb1111001100000101010100110010,
    28'sb0000011001110011100000011101,
    28'sb0000010100011000001010101010,
    28'sb1111110000000100111010100101,
    28'sb1111111000101110101100011100,
    28'sb0000001001011110001101010100,
    28'sb0000000101011011010101110100,
    28'sb1111111111101111011000101101
  };

  // D=4 (22 taps) from FilterCoef_block.sv
  localparam int NTAPS_D4 = 22;
  localparam coeff_t COEF_D4 [0:NTAPS_D4-1] = '{
    28'sb1111111101010101100110110100,
    28'sb1111111110100111100001101100,
    28'sb0000001001100001011111000010,
    28'sb0000000101110101100011100010,
    28'sb1111101110010101100000010000,
    28'sb1111111100111000000111011000,
    28'sb0000100110001100011111100011,
    28'sb1111111001100110011001100110,
    28'sb1110110001011101011000111001,
    28'sb0000101001110001110111100111,
    28'sb0100010011001100110011001101,
    28'sb0100010011001100110011001101,
  28'sb0000101001110001110111100111,
    28'sb1110110001011101011000111001,
    28'sb1111111001100110011001100110,
    28'sb0000100110001100011111100011,
    28'sb1111111100111000000111011000,
    28'sb1111101110010101100000010000,
    28'sb0000000101110101100011100010,
    28'sb0000001001100001011111000010,
    28'sb1111111110100111100001101100,
    28'sb1111111101010101100110110100
  };

  // D=8 (22 taps) from FilterCoef_block1.sv
  localparam int NTAPS_D8 = 22;
  localparam coeff_t COEF_D8 [0:NTAPS_D8-1] = '{
    28'sb1111111101010010010101000110,
    28'sb1111111110100100001111111110,
    28'sb0000001001101011010100001011,
    28'sb0000000101111111011000101011,
    28'sb1111101110000101000111101100,
    28'sb1111111100101110010010001111,
    28'sb0000100110110011110100001000,
    28'sb1111111001110000001110110000,
    28'sb1110110000001000001100010010,
    28'sb0000101001000000101101111000,
    28'sb0100010100101111000110101010,
    28'sb0100010100101111000110101010,
    28'sb0000101001000000101101111000,
    28'sb1110110000001000001100010010,
    28'sb1111111001110000001110110000,
    28'sb0000100110110011110100001000,
    28'sb1111111100101110010010001111,
    28'sb1111101110000101000111101100,
    28'sb0000000101111111011000101011,
    28'sb0000001001101011010100001011,
    28'sb1111111110100100001111111110,
    28'sb1111111101010010010101000110
  };

  // D=16 (22 taps) from FilterCoef_block2.sv
  localparam int NTAPS_D16 = 22;
  localparam coeff_t COEF_D16 [0:NTAPS_D16-1] = '{
    28'sb1111111101010010010101000110,
    28'sb1111111110100100001111111110,
    28'sb0000001001101011010100001011,
    28'sb0000000110000010101010011001,
    28'sb1111101101111110100100010000,
    28'sb1111111100101110010010001111,
    28'sb0000100111000000111010111111,
    28'sb1111111001110011100000011101,
    28'sb1110101111110100100010000000,
    28'sb0000101000110011100111000001,
    28'sb0100010101000110000010101010,
    28'sb0100010101000110000010101010,
    28'sb0000101000110011100111000001,
    28'sb1110101111110100100010000000,
    28'sb1111111001110011100000011101,
    28'sb0000100111000000111010111111,
    28'sb1111111100101110010010001111,
    28'sb1111101101111110100100010000,
    28'sb0000000110000010101010011001,
    28'sb0000001001101011010100001011,
    28'sb1111111110100100001111111110,
    28'sb1111111101010010010101000110
  };

  //=============================================
  //============ Combinational Logic ============
  //=============================================
  // Select active set
  logic [2:0] k;
  logic [7:0] D;
  always_comb begin
    k = (decim_sel > 3'd4) ? 3'd4 : decim_sel;
    D = 8'd1 << k;
  end

  // Delay line sized to max taps
  sample_t x [0:MAX_TAPS-1];
  int tapCount;
  coeff_t coef [0:MAX_TAPS-1];

  // Configure coefficients and tapCount based on D
  always_comb begin
    tapCount = 0;
    for (int i=0;i<MAX_TAPS;i++) begin
      coef[i] = '0;
    end
    unique case (D)
      8'd2: begin
        tapCount = NTAPS_D2;
        for (int i=0;i<NTAPS_D2;i++) coef[i] = COEF_D2[i];
      end
      8'd4: begin
        tapCount = NTAPS_D4;
        for (int i=0;i<NTAPS_D4;i++) coef[i] = COEF_D4[i];
      end
      8'd8: begin
        tapCount = NTAPS_D8;
        for (int i=0;i<NTAPS_D8;i++) coef[i] = COEF_D8[i];
      end
      8'd16: begin
        tapCount = NTAPS_D16;
        for (int i=0;i<NTAPS_D16;i++) coef[i] = COEF_D16[i];
      end
      default: begin
        tapCount = 1;
        coef[0]   = 28'sd134217728; // 1.0 in Q1.27 (bypass)
      end
    endcase
  end

  //=============================================
  //================= FF Logic ==================
  //=============================================
  // Shift register and MAC
  acc_t acc;
  logic out_vld_next;
  // temps for rounding/saturation (module-scope to avoid inline-decl issues)
  prod_t acc56;
  logic signed [27:0] rounded;
  logic signed [27:0] maxW, minW;
  logic sat_pos, sat_neg, sat_event;
  logic signed [W-1:0] sat_out;

  always_ff @(posedge clk) begin
    if (reset) begin
      for (int i=0;i<MAX_TAPS;i++) x[i] <= '0;
      out_sample <= '0;
      out_valid  <= 1'b0;
      ovf_flag   <= 1'b0;
    end else if (clk_enable) begin
      if (sync_reset) begin
        ovf_flag <= 1'b0;
      end
      if (in_valid) begin
        // shift
        for (int i=MAX_TAPS-1;i>0;i--) x[i] <= x[i-1];
        x[0] <= in_sample;
      end
      // compute when valid
      acc = '0;
      if (in_valid) begin
        for (int i=0;i<MAX_TAPS;i++) begin
          if (i < tapCount) begin
            acc += acc_t'($signed(x[i]) * $signed(coef[i]));
          end
        end
      end
      // Round from Q2.42 to Q1.15 by taking [54:27] and adding LSB for rounding
      // acc (>=56 bits) -> take middle 55:0 like generated code path
      acc56   = $signed(acc[55:0]);
      rounded = acc56[54:27] + $signed({1'b0, acc56[26]});

      // Saturate to W bits and detect saturation event
      // Build 28-bit signed thresholds for W-bit range
      maxW = $signed({{(28-W){1'b0}}, 1'b0, {W-1{1'b1}}});
      minW = $signed({{(28-W){1'b1}}, 1'b1, {W-1{1'b0}}});
      sat_pos = (rounded > maxW);
      sat_neg = (rounded < minW);
      sat_event = sat_pos | sat_neg;
      if (sat_pos) begin
        sat_out = {1'b0, {W-1{1'b1}}};
      end else if (sat_neg) begin
        sat_out = {1'b1, {W-1{1'b0}}};
      end else begin
        sat_out = rounded[W-1:0];
      end

      if (comp_enable && (D != 8'd1) && in_valid) begin
        out_sample <= sat_out;
        out_valid  <= 1'b1;
        if (sat_event) ovf_flag <= 1'b1; // sticky until reset/sync_reset
      end else if (in_valid) begin
        out_sample <= in_sample;
        out_valid  <= 1'b1;
      end else begin
        out_valid  <= 1'b0;
      end
    end
  end

endmodule
