module top #(
    parameter WIDTH = 32,
    parameter A1 = 16'h6473,
    parameter A2 = 16'h3C38,
    parameter B0 = 32'h40000000,
    parameter B1 = 16'h678E,
    parameter B2 = 16'h4000
)(
    input clk,
    input rst_n,
    input [WIDTH-1 : 0] data_in,
    output [WIDTH*2 - 1 : 0] data_out
);

wire system_reset;

// x[n] registers:
wire [WIDTH-1 : 0] x_0;
wire [WIDTH-1 : 0] x_1;
wire [WIDTH-1 : 0] x_2;

// multiplied by B's registers:
wire [WIDTH*2 - 1 : 0] b0_reg;
wire [WIDTH*2 - 1 : 0] b1_reg;
wire [WIDTH*2 - 1 : 0] b2_reg;
wire [WIDTH*2 - 1 : 0] b0_calc;
wire [WIDTH*2 - 1 : 0] b1_calc;
wire [WIDTH*2 - 1 : 0] b2_calc;

// multiplied by A's registers:
wire [WIDTH*2 - 1 : 0] a1_reg;
wire [WIDTH*2 - 1 : 0] a2_reg;
wire [WIDTH*2 - 1 : 0] a1_calc;
wire [WIDTH*2 - 1 : 0] a2_calc;

// system adder:
wire [WIDTH*2 - 1 : 0] adder_out;

// output system y[n]:
wire [WIDTH*2 - 1 : 0] y0_reg;

// reset synchronizer
synchronizer reset_synchronizer (
    .clk(clk),
    .enable(1'b1),
    .in(rst_n),
    .out(system_reset)
);

// x[n] registers:
parameterized_bus #(.WIDTH(WIDTH)) x0_reg_ (
    .clk(clk),
    .rst_n(system_reset),
    .data_in(data_in),
    .data_out(x_0)
);
parameterized_bus #(.WIDTH(WIDTH)) x1_reg_ (
    .clk(clk),
    .rst_n(system_reset),
    .data_in(data_in),
    .data_out(x_1)
);
parameterized_bus #(.WIDTH(WIDTH)) x2_reg_ (
    .clk(clk),
    .rst_n(system_reset),
    .data_in(data_in),
    .data_out(x_2)
);

// B's registers:
parameterized_bus #(.WIDTH(WIDTH*2)) b0_reg_ (
    .clk(clk),
    .rst_n(system_reset),
    .data_in(b0_calc),
    .data_out(b0_reg)
);
parameterized_bus #(.WIDTH(WIDTH*2)) b1_reg_ (
    .clk(clk),
    .rst_n(system_reset),
    .data_in(b1_calc),
    .data_out(b1_reg)
);
parameterized_bus #(.WIDTH(WIDTH*2)) b2_reg_ (
    .clk(clk),
    .rst_n(system_reset),
    .data_in(b2_calc),
    .data_out(b2_reg)
);

// y[n], a1, and a2 registers:
parameterized_bus #(.WIDTH(WIDTH*2)) y0_reg_ (
    .clk(clk),
    .rst_n(system_reset),
    .data_in(adder_out),
    .data_out(y0_reg)
);
parameterized_bus #(.WIDTH(WIDTH*2)) a1_reg_ (
    .clk(clk),
    .rst_n(system_reset),
    .data_in(a1_calc),
    .data_out(a1_reg)
);
parameterized_bus #(.WIDTH(WIDTH*2)) a2_reg_ (
    .clk(clk),
    .rst_n(system_reset),
    .data_in(a2_calc),
    .data_out(a2_reg)
);

// x[n] multiplication stage:
B0_calc #(.WIDTH(WIDTH*2), .B0(B0)) b0_calc_ (
    .operand_1(x_0),
    .B0_out(b0_calc)
);
B1_calc #(.WIDTH(WIDTH*2), .B1(B1)) b1_calc_ (
    .operand_1(x_1),
    .B1_out(b1_calc)
);
B2_calc #(.WIDTH(WIDTH*2), .B2(B2)) b2_calc_ (
    .operand_1(x_2),
    .B2_out(b2_calc)
);

// y[n] multiplcation stage:
A1_calc #(.WIDTH(WIDTH*2), .A1(A1)) a1_calc_ (
    .operand_1(adder_out),
    .A1_out(a1_calc)
);
A2_calc #(.WIDTH(WIDTH*2), .A2(A2)) a2_calc_ (
    .operand_1(y0_reg),
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

assign data_out = y0_reg;

endmodule