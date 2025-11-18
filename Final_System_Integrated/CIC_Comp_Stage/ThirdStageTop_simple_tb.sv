`timescale 1ns/1ps

module ThirdStageTop_simple_tb ();

  //=============================================
  //============ Parameters and vars ============
  //=============================================
  localparam int IN_W = 16;
  localparam int MAX_SAMPLES = 4096;
  localparam real CLOCK_PERIOD = 10.0; // 100 MHz
  integer i;

  //=============================================
  //============ DUT Signals ====================
  //=============================================
  reg                  clk_tb;
  reg                  rst_n_tb; // active-low asynchronous reset
  reg                  clk_enable_tb;
  reg  signed [IN_W-1:0] x_in_tb;
  reg                  x_valid_tb;
  reg                  enable_tb;
  reg                  comp_enable_tb;
  reg          [2:0]   decim_sel_tb;
  wire signed [IN_W-1:0] y_out_tb;
  wire                 y_valid_tb;
  wire        [7:0]    D_active_tb;

  //=============================================
  //============ Input/Output files =============
  //=============================================
  reg  [IN_W-1:0] mem [0:MAX_SAMPLES-1];
  integer sample_count;
  integer fout;
  string  out_fname;

  //=============================================
  //============ Clock Generator ================
  //=============================================
  initial clk_tb = 1'b0;
  always #(CLOCK_PERIOD/2.0) clk_tb = ~clk_tb;

  //=============================================
  //============ DUT Instantiation ==============
  //=============================================
  ThirdStageTop_simple DUT (
    .clk(clk_tb), .rst_n(rst_n_tb), .clk_enable(clk_enable_tb),
    .x_in(x_in_tb), .x_valid(x_valid_tb), .enable(enable_tb), .comp_enable(comp_enable_tb), .decim_sel(decim_sel_tb),
    .y_out(y_out_tb), .y_valid(y_valid_tb), .D_active(D_active_tb)
  );

  //=============================================
  //============ Initial Block ==================
  //=============================================
  initial begin
    initialize();
    // Read input hex file (relative to Simple_RTL_Design)
    $readmemh("../data_out.hex", mem);
    sample_count = MAX_SAMPLES;
    reset_task();

    out_fname = "../Output_Text/RTL_OUT.txt";
    fout = $fopen(out_fname, "w");
    if (fout == 0) begin
      $display("ERROR: could not open output file");
      $finish;
    end

    // Run one pass; adjust decim/enable here if needed
    enable_tb      = 1'b1;
    comp_enable_tb = 1'b1;
    decim_sel_tb   = 3'd1; // R=2 example
    run_from_hex(sample_count);

    $fclose(fout);
    $display("TB done. Output HEX written to %s", out_fname);
    $finish;
  end

  //=============================================
  //============ Tasks ==========================
  //=============================================
  task initialize;
    begin
      clk_enable_tb   = 1'b1;
  rst_n_tb        = 1'b0; // assert reset (active low)
      x_valid_tb      = 1'b0;
      x_in_tb         = '0;
      enable_tb       = 1'b0;
      comp_enable_tb  = 1'b0;
      decim_sel_tb    = 3'd0;
    end
  endtask

  task reset_task;
    begin
  rst_n_tb = 1'b0; #(5*CLOCK_PERIOD); // hold reset low
  rst_n_tb = 1'b1; #(5*CLOCK_PERIOD); // release reset
    end
  endtask

  task run_from_hex;
    input integer nsamp;
    begin
      x_valid_tb = 1'b1;
      for (i=0; i<nsamp; i=i+1) begin
        @(posedge clk_tb);
        x_in_tb <= mem[i];
  if (y_valid_tb) $fwrite(fout, "%04h\n", y_out_tb[15:0]);
      end
      // drain
      x_valid_tb = 1'b0;
      repeat (32) begin
        @(posedge clk_tb);
        if (y_valid_tb) $fwrite(fout, "%04h\n", y_out_tb[15:0]);
      end
    end
  endtask

endmodule
