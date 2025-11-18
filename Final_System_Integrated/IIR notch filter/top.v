module top #(
    parameter WIDTH = 32    
)(
    input clk,
    input rst_n,
    input signed [15 : 0] A1,
    input signed [15 : 0] A2,
    input signed [15 : 0] B0,
    input signed [15 : 0] B1,
    input signed [15 : 0] B2,
    input signed [WIDTH-1 : 0] data_in,
    output signed [WIDTH-1 : 0] data_out
);

wire system_reset;

// converting input to S16.14:
wire signed [WIDTH-1 : 0] converted_input;

// x[n] registers:
wire signed [WIDTH-1 : 0] x_0;
wire signed [WIDTH-1 : 0] x_1;
wire signed [WIDTH-1 : 0] x_2;

// multiplied by B's registers:
wire signed [WIDTH*2 -1 : 0] b0_reg;
wire signed [WIDTH*2 -1 : 0] b1_reg;
wire signed [WIDTH*2 -1 : 0] b2_reg;
wire signed [WIDTH*2 -1 : 0] b0_calc;
wire signed [WIDTH*2 -1 : 0] b1_calc;
wire signed [WIDTH*2 -1 : 0] b2_calc;

// multiplied by A's registers:
wire signed [WIDTH*2 -1 : 0] a1_reg;
wire signed [WIDTH*2 -1 : 0] a2_reg;
wire signed [WIDTH*2 -1 : 0] a1_calc;
wire signed [WIDTH*2 -1 : 0] a2_calc;

// system adder:
wire signed [WIDTH*2 + 4 : 0] adder_out;
wire signed [WIDTH - 1 : 0] shifted_data;

// output system y[n]:
wire signed [WIDTH - 1 : 0] y0_reg;

// reset synchronizer
// synchronizer reset_synchronizer (
//     .clk(clk),
//     .enable(1'b1),
//     .in(rst_n),
//     .out(system_reset)
// );
assign system_reset = rst_n;
input_adjust #(.WIDTH(WIDTH)) input_conv (
    .in(data_in),
    .out(converted_input)
);

// x[n] registers:
parameterized_bus #(.WIDTH(WIDTH)) x0_reg_ (
    .clk(clk),
    .rst_n(system_reset),
    .data_in(converted_input),
    .data_out(x_0)
);
parameterized_bus #(.WIDTH(WIDTH)) x1_reg_ (
    .clk(clk),
    .rst_n(system_reset),
    .data_in(x_0),
    .data_out(x_1)
);
parameterized_bus #(.WIDTH(WIDTH)) x2_reg_ (
    .clk(clk),
    .rst_n(system_reset),
    .data_in(x_1),
    .data_out(x_2)
);

// B's registers:
parameterized_bus #(.WIDTH(2*WIDTH)) b0_reg_ (
    .clk(clk),
    .rst_n(system_reset),
    .data_in(b0_calc),
    .data_out(b0_reg)
);
parameterized_bus #(.WIDTH(2*WIDTH)) b1_reg_ (
    .clk(clk),
    .rst_n(system_reset),
    .data_in(b1_calc),
    .data_out(b1_reg)
);
parameterized_bus #(.WIDTH(2*WIDTH)) b2_reg_ (
    .clk(clk),
    .rst_n(system_reset),
    .data_in(b2_calc),
    .data_out(b2_reg)
);

// y[n], a1, and a2 registers:
parameterized_bus #(.WIDTH(WIDTH)) y0_reg_ (
    .clk(clk),
    .rst_n(system_reset),
    .data_in(shifted_data),
    .data_out(y0_reg)
);
parameterized_bus #(.WIDTH(2*WIDTH)) a1_reg_ (
    .clk(clk),
    .rst_n(system_reset),
    .data_in(a1_calc),
    .data_out(a1_reg)
);
parameterized_bus #(.WIDTH(2*WIDTH)) a2_reg_ (
    .clk(clk),
    .rst_n(system_reset),
    .data_in(a2_calc),
    .data_out(a2_reg)
);

// x[n] multiplication stage:
B0_calc #(.WIDTH(WIDTH)) b0_calc_ (
    .operand_1(x_0),
    .B0(B0),
    .B0_out(b0_calc)
);
B1_calc #(.WIDTH(WIDTH)) b1_calc_ (
    .operand_1(x_1),
    .B1(B1),
    .B1_out(b1_calc)
);
B2_calc #(.WIDTH(WIDTH)) b2_calc_ (
    .operand_1(x_2),
    .B2(B2),
    .B2_out(b2_calc)
);

// y[n] multiplcation stage:
A1_calc #(.WIDTH(WIDTH)) a1_calc_ (
    .operand_1(shifted_data),
    .A1(A1),
    .A1_out(a1_calc)
);
A2_calc #(.WIDTH(WIDTH)) a2_calc_ (
    .operand_1(y0_reg),
    .A2(A2),
    .A2_out(a2_calc)
);

// system adder:
adder #(.WIDTH(WIDTH)) system_adder_ (
    .operand_1(b0_reg),
    .operand_2(b1_reg),
    .operand_3(b2_reg),
    .operand_4(a1_reg),
    .operand_5(a2_reg),
    .out(adder_out)
);

arth_shift #(.WIDTH(WIDTH)) arithmetic_shift_Y (
    .operand_1(adder_out),
    .out(shifted_data)
);

assign data_out = y0_reg;

endmodule