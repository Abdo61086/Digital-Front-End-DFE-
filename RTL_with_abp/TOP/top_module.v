module top_module #(
  parameter ABP_ADDR_WIDTH = 4,
  parameter ABP_DATA_WIDTH = 32,
  parameter DFE_DATA_WIDTH = 16
) (
                          
  // APB Signals
  input                       PCLK,
  input                       PRESETn,
  input                       PSEL,
  input                       PENABLE,
  input                       PWRITE,
  input      [ABP_ADDR_WIDTH-1:0] PADDR,
  input      [ABP_DATA_WIDTH-1:0] PWDATA,
  output reg [ABP_DATA_WIDTH-1:0] PRDATA,

  //dfe signals
  input      [DFE_DATA_WIDTH-1:0] input_data,
  output     [DFE_DATA_WIDTH-1:0] output_data

  );
  
  //REG0 control_reg address 0, enable[0 1 2] bypass [3 4 5] factor [6 7 8]
  //REG1 status_reg
  //REG2,REG3 0.5xREG4 0.5xREG4 REG5,REG6  Notch

  localparam N_REG = 7;

  reg [ABP_DATA_WIDTH-1:0] REG [N_REG-1:0];

  wire [5*DFE_DATA_WIDTH-1:0] filter_coeff_1, filter_coeff_2;
  assign filter_coeff_1 = {REG[2], REG[3], REG[4][31:16]};
  assign filter_coeff_2 = {REG[4][15:0], REG[5], REG[6]};

  integer i;
  always @(posedge PCLK, negedge PRESETn) begin
    if(!PRESETn) begin
      for(i = 0; i < N_REG; i = i + 1)
        REG[i] = 0;
    end 
    else if (PSEL && PENABLE && PWRITE) begin
        REG[PADDR] <= PWDATA;  

    end
  end

  always @(*) begin
    if (PSEL && !PWRITE) begin
        PRDATA = REG[PADDR];  

    end else begin
        PRDATA = 0;
    end
  end



 dfe_top #(.DATA_WIDTH(DFE_DATA_WIDTH)) u_dft_top (
    .CLK(PCLK),
    .RST(PRESETn),
    .CIC_Decimation_Factor(REG[0][11:9]),
    .data_in(input_data),
    .data_out(output_data),
    .filter_coeff_notch_1(filter_coeff_1),
    .filter_coeff_notch_2(filter_coeff_2),

    .FD_EN(REG[0][0]),                                                     
    .NOTCH_EN_1(REG[0][1]),                                              
    .NOTCH_EN_2(REG[0][2]),                                              
    .CIC_EN(REG[0][3]),                                              
    .CLKDIV_EN(REG[0][4]),                                             
                                                    
    .FD_bypass(REG[0][5]),                                                
    .NOTCH_bypass_1(REG[0][6]),                                                 
    .NOTCH_bypass_2(REG[0][7]),                                                 
    .CIC_bypass(REG[0][8])                                                
    
 );

endmodule
