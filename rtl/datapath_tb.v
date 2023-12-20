`timescale 1ns / 1ps

module datapath_tb ();

localparam LANES = 64;
localparam DATAW = 512;
localparam IPREC = 8;
localparam OPREC = 32;
localparam MEM_DEPTH = 512;
localparam ADDRW = $clog2(MEM_DEPTH);
localparam CLK_PERIOD = 4;

reg clk, rst, i_valid, i_accum, i_last, i_reduce;
reg [DATAW-1:0] i_dataa, i_datab;
reg [IPREC-1:0] i_datac;
reg [ADDRW-1:0] i_accum_addr;
wire o_valid;
wire [OPREC-1:0] o_result;

datapath # (
	.LANES(LANES),
	.DATAW(DATAW),
	.IPREC(IPREC),
	.OPREC(OPREC),
	.MEM_DEPTH(MEM_DEPTH)
) dut (
	.clk(clk),
	.rst(rst),
	.i_valid(i_valid),
	.i_dataa(i_dataa),
	.i_datab(i_datab),
	.i_datac(i_datac),
	.i_accum_addr(i_accum_addr),
	.i_accum(i_accum),
	.i_last(i_last),
	.i_reduce(i_reduce),
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
	i_datac = 'd0;
	i_accum_addr = 'd0;
	i_accum = 1'b0;
	i_last = 1'b0;
	i_reduce = 1'b0;
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
	#(5*CLK_PERIOD);
	
	i_valid = 1'b1;
	i_accum = 1'b1;
	i_last = 1'b1;
	i_reduce = 1'b1;
	i_dataa = {8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 
				  8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 
				  8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 
				  8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1};
	i_datab = {8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 
				  8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 
				  8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 
				  8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1};
	i_datac = 'd5;
	#(CLK_PERIOD);
	
	i_valid = 1'b0;
	#(5*CLK_PERIOD);
end

initial begin
	while (1'b1) begin
		if (o_valid) begin
			if (o_result == 'd133) begin
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