//=============================================
//========= Simple Compensation FIR (DFE) =====
//=============================================
// Per-D coefficient sets (D=2,4,8,16) selected by decim_sel.
// Operates at CIC output rate. If enable=0 or D=1, bypass input.
// Fixed-point: in/out Q1.15 (16-bit). Straight MAC, truncate+sat.
`timescale 1ns/1ns

module CompensationFIR_simple #(
  parameter int W    = 16,
  parameter int FRAC = 15
) (
  input  logic               clk,
  input  logic               rst_n,      // active-low asynchronous reset
  input  logic               clk_enable,
  input  logic               in_valid,
  input  logic               enable,       // compensation enable
  input  logic       [2:0]   decim_sel,
  input  logic signed [W-1:0] in_sample,   // Q1.15
  
  output logic signed [W-1:0] out_sample,  // Q1.15
  output logic                out_valid
);
  //=============================================
  //============ Parameters and Vars ============
  //=============================================
  // Decimation factor
  logic [2:0] k; logic [7:0] D;
  always_comb begin
    k = (decim_sel > 3'd4) ? 3'd4 : decim_sel;
    D = 8'd1 << k;
  end

  // Coeff sets (reuse 28-bit Q1.27 constants; later scaled to Q1.15)
  // Only a subset shown; for brevity keep arrays identical to main RTL but treat scale.
  localparam int MAX_TAPS = 22;
  typedef logic signed [27:0] coeff_raw_t; // Q1.27
  typedef logic signed [47:0] prod_t;       // 28+20 (after scaling) conservative
  typedef logic signed [55:0] acc_t;        // accumulation width

  // D-specific counts
  localparam int NTAPS_D2 = 21;
  localparam int NTAPS_D4 = 22;
  localparam int NTAPS_D8 = 22;
  localparam int NTAPS_D16= 22;

  // Coefficient arrays (copied from main file)
  localparam coeff_raw_t COEF_D2 [0:NTAPS_D2-1] = '{
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
  localparam coeff_raw_t COEF_D4 [0:NTAPS_D4-1] = '{
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
  localparam coeff_raw_t COEF_D8 [0:NTAPS_D8-1] = '{
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
  localparam coeff_raw_t COEF_D16 [0:NTAPS_D16-1] = '{
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
  // Active taps and coefficient selection
  int tapCount; coeff_raw_t coef_raw [0:MAX_TAPS-1];
  always_comb begin
    tapCount = 1;
    for (int i=0;i<MAX_TAPS;i++) coef_raw[i] = 0;
    unique case (D)
      8'd2: begin tapCount = NTAPS_D2; for (int i=0;i<NTAPS_D2;i++) coef_raw[i] = COEF_D2[i]; end
      8'd4: begin tapCount = NTAPS_D4; for (int i=0;i<NTAPS_D4;i++) coef_raw[i] = COEF_D4[i]; end
      8'd8: begin tapCount = NTAPS_D8; for (int i=0;i<NTAPS_D8;i++) coef_raw[i] = COEF_D8[i]; end
      8'd16: begin tapCount = NTAPS_D16; for (int i=0;i<NTAPS_D16;i++) coef_raw[i] = COEF_D16[i]; end
      default: begin tapCount = 1; coef_raw[0] = 28'sd134217728; end // 1.0 Q1.27
    endcase
  end

  // Scale coefficients from Q1.27 to Q1.15 by rounding (drop 12 LSBs)
  typedef logic signed [15:0] coeff_t; // Q1.15 storage for MAC
  coeff_t coef [0:MAX_TAPS-1];
  always_comb begin
    for (int i=0;i<MAX_TAPS;i++) begin
      // Take bits [27:12] with rounding using bit 11, no automatic temps
      coef[i] = coeff_t'(coef_raw[i][27:12] + coef_raw[i][11]);
    end
  end

  // Delay line
  logic signed [W-1:0] x [0:MAX_TAPS-1];
  
  // Accumulator
  acc_t acc;
  acc_t acc_rnd; // rounded accumulator
  // Saturation temps declared ahead (ModelSim requires decls before statements)
  logic signed [W-1:0] candidate;
  logic overflow_pos, overflow_neg;

  //=============================================
  //================= FF Logic ==================
  //=============================================
  // Shift + MAC
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      for (int i=0;i<MAX_TAPS;i++) x[i] <= '0;
      out_sample <= '0; out_valid <= 1'b0;
    end else if (clk_enable) begin
      if (in_valid) begin
        for (int i=MAX_TAPS-1;i>0;i--) x[i] <= x[i-1];
        x[0] <= in_sample;
        acc = '0;
        for (int i=0;i<tapCount;i++) begin
          acc += acc_t'($signed(x[i]) * $signed(coef[i]));
        end
        // Round and rescale from Q2.30 back to Q1.15
        // acc is at least 56 bits wide; add 2^(FRAC-1) for round-to-nearest then shift right FRAC
  acc_rnd = acc + (acc_t'((1) << (FRAC-1)));
        // Extract aligned 16-bit candidate: bits [FRAC+W-1 : FRAC]
        candidate = $signed(acc_rnd[FRAC+W-1:FRAC]);
        // Overflow detect on the rounded value: any non-sign bits above the slice
        overflow_pos = (~acc_rnd[55]) & (|acc_rnd[55-1:FRAC+W]);
        overflow_neg = (acc_rnd[55])  & (~(&acc_rnd[55-1:FRAC+W]));
        if (overflow_pos)      out_sample <= {1'b0,{(W-1){1'b1}}};
        else if (overflow_neg) out_sample <= {1'b1,{(W-1){1'b0}}};
        else                   out_sample <= candidate;
        out_valid <= enable & (D != 8'd1);
        if (~enable || D==8'd1) begin
          // bypass: just forward sample
          out_sample <= in_sample;
          out_valid  <= 1'b1;
        end
      end else begin
        out_valid <= 1'b0;
      end
    end
  end
endmodule
