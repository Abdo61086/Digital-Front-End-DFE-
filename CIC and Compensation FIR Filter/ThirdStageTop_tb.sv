`timescale 1ns/1ps

module ThirdStageTop_tb ();

  //=============================================
  //============ Parameters and vars ============
  //=============================================
  parameter CLOCK_PERIOD = 166.667; // 6 MHz
  integer  i;

  //=============================================
  //============ DUT Signals ====================
  //=============================================
  reg                  clk_tb;
  reg                  reset_tb;           // active-high
  reg                  clk_enable_tb;
  reg  signed [15:0]   x_in_tb;
  reg                  x_valid_tb;
  reg                  ctrl_enable_tb;
  reg                  ctrl_reset_tb;
  reg          [7:0]   ctrl_decim_sel_tb;
  reg                  ctrl_comp_enable_tb;
  wire                 ce_out_tb;
  wire signed [27:0]   y_out_tb;
  wire                 y_valid_tb;
  wire        [7:0]    status_D_active_tb;
  wire        [7:0]    status_overflow_tb;
  wire                 status_ready_tb;

  //=============================================
  //============ Output logging =================
  //=============================================
  integer fout;
  integer out_count;

  //=============================================
  //============ Clock Generator ================
  //=============================================
  // Ensure clock has a defined value before the toggler starts (avoid race)
  initial clk_tb = 1'b0;
  always #(CLOCK_PERIOD/2) clk_tb = ~clk_tb;

  //=============================================
  //============ DUT Instantiation ==============
  //=============================================
  CIC_ThirdStageTop DUT (
    .clk(clk_tb),
    .reset(reset_tb),
    .clk_enable(clk_enable_tb),
    .x_in(x_in_tb),
    .x_valid(x_valid_tb),
    .ctrl_enable(ctrl_enable_tb),
    .ctrl_reset(ctrl_reset_tb),
    .ctrl_decim_sel(ctrl_decim_sel_tb),
    .ctrl_comp_enable(ctrl_comp_enable_tb),
    .ce_out(ce_out_tb),
    .y_out(y_out_tb),
    .y_valid(y_valid_tb),
    .status_D_active(status_D_active_tb),
    .status_overflow(status_overflow_tb),
    .status_ready(status_ready_tb)
  );

  //=============================================
  //============ Initial Block ==================
  //=============================================
  initial begin
    // init
    initialize();

    // Open CSV for captured outputs at decimated rate
    // Columns: sim_time_ns, decim_sel_k, comp_en, D_active, y_valid, y_out_s28_15, status_overflow
    fout = $fopen("ThirdStageTop_out.csv", "w");
    if (fout == 0) begin
      $display("ERROR: could not open output CSV file");
      $finish;
    end
    $fwrite(fout, "time_ns,decim_sel,comp_en,D_active,y_valid,y_out_s28_15,status_overflow\n");
    out_count = 0;

    // reset
    reset_task();

    // Basic runs similar to divider TB style
    // D=1, comp off
    run_stream(1'b1, 8'd0, 1'b0, 1024);

    // D=2, comp off then on
    run_stream(1'b1, 8'd1, 1'b0, 1024);
    run_stream(1'b1, 8'd1, 1'b1, 1024);

    // D=4, comp on
    run_stream(1'b1, 8'd2, 1'b1, 1024);

    // D=8, comp on
    run_stream(1'b1, 8'd3, 1'b1, 1024);

    // D=16, comp on
    run_stream(1'b1, 8'd4, 1'b1, 1024);

    // Close log and finish simulation cleanly
    $fclose(fout);
    $display("TB done. Output CSV: %s", "ThirdStageTop_out.csv");
    $finish;
  end

  //=============================================
  //============ Tasks ==========================
  //=============================================

  // Signals Initialization 
  task initialize;
    begin
      clk_tb               = 1'b0;
      reset_tb             = 1'b1;
      clk_enable_tb        = 1'b0;
      x_in_tb              = '0;
      x_valid_tb           = 1'b0;
      ctrl_enable_tb       = 1'b0;
      ctrl_reset_tb        = 1'b0;
      ctrl_decim_sel_tb    = 8'd0;
      ctrl_comp_enable_tb  = 1'b0;
    end
  endtask

  // Reset
  task reset_task;
    begin
      reset_tb = 1'b1; #(CLOCK_PERIOD);
      reset_tb = 1'b0; #(CLOCK_PERIOD);
      reset_tb = 1'b1; #(CLOCK_PERIOD);
    end
  endtask

  // Generate a stream of samples with given enable/decim/comp
  task run_stream;
    input  enable_path;
    input  [7:0] decim_sel;
    input  comp_en;
    input  integer cycles;

    begin
      ctrl_enable_tb      = enable_path;
      ctrl_decim_sel_tb   = decim_sel;
      ctrl_comp_enable_tb = comp_en;
      clk_enable_tb       = 1'b1;
      x_valid_tb          = 1'b1; // continuous stream
      ctrl_reset_tb       = 1'b0; // keep pipeline active

      for (i = 0; i < cycles; i = i + 1) begin
        // simple ramp input in Q1.15, cycles through -0.5 .. +0.5
        x_in_tb = $signed(16'sd16384) * $signed((i % 64) - 32) >>> 6; // scale
        #(CLOCK_PERIOD);
        // Log outputs at decimated rate
        if (y_valid_tb) begin
          out_count = out_count + 1;
          $fwrite(fout, "%0t,%0d,%0d,%0d,%0d,%0d,%0d\n",
                  $time,
                  decim_sel[2:0],
                  comp_en,
                  status_D_active_tb,
                  y_valid_tb,
                  y_out_tb,
                  status_overflow_tb);
        end
      end

      // small gap
      x_valid_tb = 1'b0; #(10*CLOCK_PERIOD);
    end
  endtask

endmodule
