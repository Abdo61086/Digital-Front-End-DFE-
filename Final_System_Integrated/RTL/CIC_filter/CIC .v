module CIC #(
  parameter WIDTH = 16,
  parameter BIT_GROWTH = 12
) (
    input clk,
    input rst_n,
    input signed [WIDTH-1:0] x_n,
    input [4:0] Decimation_Factor, // Decimation Factor D = 2^k, k in [0..4]

    output [WIDTH+BIT_GROWTH-1:0] y_n
);
// Parameters and Internal Connections
  wire [WIDTH+BIT_GROWTH-1:0] x_n_ext;
  reg  [WIDTH+BIT_GROWTH-1:0] Int_1_reg, Int_2_reg, Int_3_reg;
  reg  [WIDTH+BIT_GROWTH-1:0] Comb_1_reg, Comb_2_reg, Comb_3_reg;

  wire [WIDTH+BIT_GROWTH-1:0] Int_1_out, Int_2_out, Int_3_out;
  wire [WIDTH+BIT_GROWTH-1:0] Comb_1_out, Comb_2_out, Comb_3_out;

// --- Decimation Strobe Logic Variables ---
  reg [3:0] dec_cnt;       // Counter for decimation
  reg Sample_Flag;         // Strobe signal for decimated rate
  wire [4:0] D;             // Actual Decimation Factor D = 1, 2, 4, 8, 16

// Sign Extension
assign x_n_ext = {{BIT_GROWTH{x_n[WIDTH-1]}}, x_n};
  // Calculate actual D from the 3-bit input
// ================ Integrator Section (High Rate) ================
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      Int_1_reg <= 0;
      Int_2_reg <= 0;
      Int_3_reg <= 0;
    end else begin
      Int_1_reg <= Int_1_out;
      Int_2_reg <= Int_2_out;
      Int_3_reg <= Int_3_out;
    end
  end

  // Wires Assignment
  assign Int_1_out = x_n_ext   + Int_1_reg;
  assign Int_2_out = Int_1_reg + Int_2_reg;
  assign Int_3_out = Int_2_reg + Int_3_reg;



// ================ Comb Section (Low Rate) ==============

// Comb Stages Registers (Gated by Sample_Flag)
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      Comb_1_reg <= 0;
      Comb_2_reg <= 0;
      Comb_3_reg <= 0;
    end else begin
      Comb_1_reg <= Int_3_out;

      Comb_2_reg <= Comb_1_out;
      Comb_3_reg <= Comb_2_out;
    end
  end

  // Wires Assignment 
  assign Comb_1_out = Int_3_out - Comb_1_reg;

  assign Comb_2_out = Comb_1_out - Comb_2_reg;
  assign Comb_3_out = Comb_2_out - Comb_3_reg;
  



  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      dec_cnt <= 'd0;
      Sample_Flag <= 1'b0;
    end else begin
      if (Decimation_Factor == 1) begin
        dec_cnt <= 'd0;
        Sample_Flag <= 1'b1;
      end else if (dec_cnt == Decimation_Factor - 1) begin
        dec_cnt <= 'd0;
        Sample_Flag <= 1'b1; // Strobe pulse
      end else begin
        dec_cnt <= dec_cnt + 1;
        Sample_Flag <= 1'b0;
      end
    end
  end

// Latch the decimated sample from the Integrator output
  reg [WIDTH+BIT_GROWTH-1:0] decimated_sample;
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      decimated_sample <= '0;
    end else if (Sample_Flag) begin // Latch only when strobe is high
      decimated_sample <= Comb_3_out;
    end
  end

  // Output Assignment
  assign y_n = decimated_sample;
endmodule
