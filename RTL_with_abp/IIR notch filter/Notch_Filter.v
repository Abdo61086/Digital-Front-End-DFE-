module Notch_Filter #(
    parameter width = 16
)(
    input CLK,
    input rst_n,
    input EN,
    input bypass,
    input [5*width-1:0] filter_coeff,
    input signed [width-1:0] x_n, // input S16.14
    output signed [width-1:0] y_n  // output S16.15  
);
    reg signed [width-1:0] x_n_1, x_n_2;
    reg signed [width-1:0] y_n_1, y_n_2, y_n_reg;
    wire signed [width-1:0] y_n_comp;

    wire signed [width-1:0] b0, b1, b2, a1, a2;

    wire signed [2*width-1:0] adder; 

    
    assign {b0, b1, b2, a1, a2} = filter_coeff;
    
    assign adder = b0*x_n + b1*x_n_1 + b2*x_n_2- a1*y_n_1 - a2*y_n_2;

    assign y_n_comp = adder >>> 14;

    always @(posedge CLK, negedge rst_n) begin
        if(!rst_n) begin
            x_n_1 <= 0;
            x_n_2 <= 0;
            y_n_1 <= 0;
            y_n_2 <= 0;
            y_n_reg <= 0;
        end
        else if(EN) begin
            x_n_1 <= x_n;
            x_n_2 <= x_n_1;

            y_n_1 <= y_n_comp;
            y_n_2 <= y_n_1;
            y_n_reg <= y_n_comp;
        end
    end

    assign y_n = (bypass) ? x_n : y_n_reg;
endmodule