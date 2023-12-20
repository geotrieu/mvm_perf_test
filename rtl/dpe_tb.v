`timescale 1ns / 1ps

module dpe_tb ();

localparam LANES = 64;
localparam DATAW = 512;
localparam IPREC = 8;
localparam MPREC = 2 * IPREC;
localparam NUM_MULT = DATAW / IPREC;
localparam OPREC = 32;
localparam ADDER_STAGES = $clog2(LANES);
localparam CLK_PERIOD = 4;

reg clk, rst, i_valid;
reg [DATAW-1:0] i_dataa, i_datab;
wire o_valid;
wire [OPREC-1:0] o_result;

dpe dut (
	.clk(clk),
	.rst(rst),
	.i_valid(i_valid),
	.i_dataa(i_dataa),
	.i_datab(i_datab),
	.o_valid(o_valid),
	.o_result(o_result)
);

initial begin
	clk = 1'b0;
	forever begin
		#(CLK_PERIOD/2) clk = !clk;
	end
end

initial begin
	rst = 1'b1;
	i_valid = 1'b0;
	i_dataa = 'd0;
	i_datab = 'd0;
	#(CLK_PERIOD);
	
	rst = 1'b0;
	i_valid = 1'b1;
	i_dataa = {8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 
				  8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 
				  8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 
				  8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1};
	i_datab = {8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 
				  8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 
				  8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 
				  8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1};
	#(CLK_PERIOD);
	
	i_valid = 1'b0;
	#(CLK_PERIOD);
end

initial begin
	while (1'b1) begin
		if (o_valid) begin
			if (o_result == 'd64) begin
				$display("Simulation PASSED!");
			end else begin
				$display("Simulation FAILED!");
			end
			$stop();
		end
		#(CLK_PERIOD);
	end
end

endmodule