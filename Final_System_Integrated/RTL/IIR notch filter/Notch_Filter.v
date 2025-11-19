module Notch_Filter #(
    parameter width = 16,
    parameter signed b0 = 0,
    parameter signed b1 = 0,
    parameter signed b2 = 0,
    parameter signed a1 = 0,
    parameter signed a2 = 0

)(
    input CLK,
    input rst_n,
    input enable,
    input signed [width-1:0] x_n, // input S16.14
    output reg signed [width-1:0] y_n  // output S16.15  
);
    reg signed [width-1:0] x_n_1, x_n_2;
    reg signed [width-1:0] y_n_1, y_n_2;
    wire signed [width-1:0] y_n_comp;

    
    reg signed [2*width-1:0] adder; 
    always @ (*) begin
        if (enable)
            adder = b0*x_n + b1*x_n_1 + b2*x_n_2- a1*y_n_1 - a2*y_n_2;
        else
            adder = {(2*width-1){1'b0}};
    end

    assign y_n_comp = adder >>> 14;

    always @(posedge CLK, negedge rst_n) begin
        if(!rst_n) begin
            x_n_1 <= 0;
            x_n_2 <= 0;
            y_n_1 <= 0;
            y_n_2 <= 0;
            y_n <= 0;
        end
        else begin
            x_n_1 <= x_n;
            x_n_2 <= x_n_1;

            y_n_1 <= y_n_comp;
            y_n_2 <= y_n_1;
            y_n <= y_n_comp;
        end
    end
endmodule