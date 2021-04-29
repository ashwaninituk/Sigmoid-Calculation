`timescale 1ns/1ps
//Test Bench for sigmoid calculation.
module test;

  localparam width = 16;

  reg [width-1:0] x_in, y_in;
  reg [31:0] theta;
  reg clk;

  wire [width-1:0] cosh, sinh, exp;
  wire [width:0] denom;
  
  wire signed [63:0] sigmoid;

  //localparam An = 1.205*16000;
  localparam An = 1.205*16000;
  
  top_dsp td0 (clk, cosh, sinh, x_in, y_in, theta, exp, denom, sigmoid);
  
  //assign sigmoid = 16000000/DENOM;

  initial 
  begin
    theta = 32'h0;
    x_in = 0;
    y_in = 0;
    clk = 'b0;
  end
	 
  always #5 clk = !clk;

	 initial
		 begin
		 //Theta Input Format: 0.549 deg = 0.549/4 * 2^32 = 32'b00100011001001111101010011110101 = atanh(2^-1)
		 //Theta inputs should be in 2 complement form for signed operations.
		 //Testcase 1
		 #500 x_in = An;                                     
		 theta = 'b00100011001001111101010011110101; //0.549   
		 //Testcase 2
		 #1000
		 theta = 'b00010011001100110011001100110011; // 0.3
		 //Testcase 3
		  #1000
		 theta = 'b00000110011001100110011001100110; // 0.1
		 //Testcase 4
		 #1000
		 theta = 'b11100110011001100110011001100110; // -0.4
		 //Testcase 5
		 #1000
		 theta = 'b00100110011001100110011001100111; // 0.6
		 //Testcase 6
		 #1000
		 theta = 'b00101100110011001100110011001101; // 0.7
		 //Testcase 7
		 #1000
		 theta = 'b11010011001100110011001100110011; // -0.7
		 #1000;
		 //Terminating the simulation
		 #5 $stop;
		 #5 $finish;
		end
endmodule
