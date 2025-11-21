module Fractional_Decimator #(
    parameter DATA_WIDTH = 16,
    parameter FRAC_WIDTH = 15,
    parameter TAPS_NUM = 138
) (
    input CLK,
    input RST, //rst_n
    input EN,
    input bypass,
    input signed [DATA_WIDTH-1:0] x_n,
    output signed [DATA_WIDTH-1:0] y_m,
    output reg valid
);
    localparam integer MUX_NUM = TAPS_NUM/3;

    reg signed [DATA_WIDTH-1:0] H [0:TAPS_NUM-1];

    wire signed [2*DATA_WIDTH-1:0] MUL [0:MUX_NUM-1];

    reg [1:0] counter;
    always @(posedge CLK, negedge RST) begin
        if(!RST) begin
            counter <= 0;
        end
        else if(EN) begin 
            counter <= (counter != 0) ? counter-1 : 2;
        end
    end

    genvar i;
    generate
        for (i = 0; i < MUX_NUM; i = i + 1) begin
            reg signed [DATA_WIDTH-1:0] MUX;
            always @(*) begin
                case (counter)
                    0 : MUX = H[0+3*i];
                    1 : MUX = H[1+3*i];
                    2 : MUX = H[2+3*i];
                    default: 
                        MUX = 0;
                endcase
            end
            assign MUL[i] = x_n_up * MUX;
        end
    endgenerate

    // Addition Chain
    wire signed [2*DATA_WIDTH-1:0] adder [0:MUX_NUM-2];

    genvar i2;
    generate
        for (i2 = 0; i2 < MUX_NUM-1; i2 = i2 + 1) begin //the is 3* (MUX_NUM-1) delays in the path
            reg signed [2*DATA_WIDTH-1:0] d0, d1, d2;
            always @(posedge CLK, negedge RST) begin
                if(!RST) begin
                    d0 <= 0;
                    d1 <= 0;
                    d2 <= 0;
                end
                else begin
                    d0 <= (i2 != MUX_NUM-2) ? adder[i2+1] :  MUL[i2+1];
                    d1 <= d0;
                    d2 <= d1;
                end 
            end
            assign adder[i2] = d2 + MUL[i2];
        end
    endgenerate


    //accumelator
    
    reg signed [2*DATA_WIDTH-1:0] accum, y_m_reg;
    wire signed [2*DATA_WIDTH-1:0] y_comb;
    
    assign y_comb = (counter != 0) ? (adder[0] + accum) : 0;

    always @(posedge CLK, negedge RST) begin
        if(!RST) begin
            accum = 0;
        end
        else if(EN) begin
            accum <= y_comb;
        end
    end

    always @(posedge CLK, negedge RST) begin
        if(!RST) begin
            y_m_reg <= 0;
            valid <= 0;
        end
        else if (EN && counter == 0) begin
            y_m_reg <= (adder[0] + accum) >>> FRAC_WIDTH;
            valid <= 1;
        end
        else    
            valid <= 0;
    end
    assign y_m = (bypass) ? x_n : y_m_reg;
endmodule


