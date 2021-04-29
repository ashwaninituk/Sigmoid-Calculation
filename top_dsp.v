`timescale 1ns/1ps
//Module for sigmoid, cosh and sinh calculation.
module top_dsp(clock, cosh, sinh, x_in, y_in, theta, exp, denom, sigmoid);

  parameter width = 16;
  parameter scale_factor1 = 16000;
  parameter scale_factor2 = 1000;

  // Inputs
  input clock;
  input signed [width-1:0] x_in, y_in;
  input signed [31:0] theta;

  // Outputs
  output signed  [width-1:0] sinh, cosh, exp;
  output signed [width:0] denom;
  output signed [63:0] sigmoid;

  //Table of tanh inverse values. Out of this only 16 are used. 
  //The rest of the entries will be used for extending precision of result to 32 bits.
  
  wire signed [31:0] tanh_inv [0:30];

  assign tanh_inv[01] = 'b00100011001001111101010011110101;
  assign tanh_inv[02] = 'b00010000010110001010111011111011;
  assign tanh_inv[03] = 'b00001000000010101100010010001110;
  assign tanh_inv[04] = 'b00000100000000010101011000100011;
  assign tanh_inv[05] = 'b00000010000000000010101010110001;
  assign tanh_inv[06] = 'b00000001000000000000010101010110;
  assign tanh_inv[07] = 'b00000000100000000000000010101010;
  assign tanh_inv[08] = 'b00000000010000000000000000010100;
  assign tanh_inv[09] = 'b00000000001000000000000000000010;
  assign tanh_inv[10] = 'b00000000000100000000000000000000;
  assign tanh_inv[11] = 'b00000000000010000000000000000000;
  assign tanh_inv[12] = 'b00000000000000111111111111111111;
  assign tanh_inv[13] = 'b00000000000000100000000000000000;
  assign tanh_inv[14] = 'b00000000000000010000000000000000;
  assign tanh_inv[15] = 'b00000000000000000111111111111111;
  assign tanh_inv[16] = 'b00000000000000000100000000000000;
  assign tanh_inv[17] = 'b00000000000000000010000000000000;
  assign tanh_inv[18] = 'b00000000000000000001000000000000;
  assign tanh_inv[19] = 'b00000000000000000000100000000000;
  assign tanh_inv[20] = 'b00000000000000000000010000000000;
  assign tanh_inv[21] = 'b00000000000000000000001000000000;
  assign tanh_inv[22] = 'b00000000000000000000000100000000;
  assign tanh_inv[23] = 'b00000000000000000000000010000000;
  assign tanh_inv[24] = 'b00000000000000000000000001000000;
  assign tanh_inv[25] = 'b00000000000000000000000000100000;
  assign tanh_inv[26] = 'b00000000000000000000000000010000;
  assign tanh_inv[27] = 'b00000000000000000000000000001000;
  assign tanh_inv[28] = 'b00000000000000000000000000000100;
  assign tanh_inv[29] = 'b00000000000000000000000000000010;
  assign tanh_inv[30] = 'b00000000000000000000000000000001;
  assign tanh_inv[00] = 'b00000000000000000000000000000000;

  reg signed [width:0] x_tmp [1:width-1];
  reg signed [width:0] y_tmp [1:width-1];
  reg signed    [32:0] z_tmp [1:width-1];

  wire [1:0] quadrant;
  assign quadrant = theta[31:30];

  //Sign adjustmenf of the input 
  
  always @(posedge clock)
  begin
    case(quadrant)
      2'b00,2'b11:begin
							x_tmp[1] <= x_in;
							y_tmp[1] <= y_in;
							z_tmp[1] <= theta;
						end
      2'b01:begin
					x_tmp[1] <= -y_in;
					y_tmp[1] <= x_in;
					z_tmp[1] <= {2'b00,theta[29:0]};
				end
      2'b10:begin
					x_tmp[1] <= y_in;
					y_tmp[1] <= -x_in;
					z_tmp[1] <= {2'b11,theta[29:0]};
				end
		default:begin
						x_tmp[1] <= x_in;
						y_tmp[1] <= y_in;
						z_tmp[1] <= theta;
				  end
    endcase
  end


  //Iterations using geb=nerate block
  genvar i;

  generate
  for (i=1; i < (width-1); i=i+1) //This loop tries to reduce the input andle to zero.
  begin: xyz
    wire signed [width:0] x_shftr, y_shftr;

    assign x_shftr = x_tmp[i] >>> i; // Shifting for tanh calculations
    assign y_shftr = y_tmp[i] >>> i;

    always @(posedge clock) //This block perfroms the add/subtraction operations with m = -1.
    begin
	 if(z_tmp[i][31])  //For negative sign after angle subtraction
	 begin
		x_tmp[i+1] <= x_tmp[i] - y_shftr;
      y_tmp[i+1] <= y_tmp[i] - x_shftr;
      z_tmp[i+1] <= z_tmp[i] + tanh_inv[i];
	 end
	 else  //For positive sign after angle subtraction
	 begin
		x_tmp[i+1] <= x_tmp[i] + y_shftr;
      y_tmp[i+1] <= y_tmp[i] + x_shftr;
      z_tmp[i+1] <= z_tmp[i] - tanh_inv[i];
	 end
	 end
  end
  endgenerate

  //Output Assignment
  
  assign cosh = x_tmp[width-1];
  assign sinh = y_tmp[width-1];
  assign exp = cosh + sinh;
  assign denom = exp + scale_factor1;
  assign sigmoid = (scale_factor1*scale_factor2)/denom;

endmodule
