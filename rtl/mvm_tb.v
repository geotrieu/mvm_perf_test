`timescale 1ns / 1ps

module mvm_tb ();

localparam DATAW = 512;         // Bitwidth of axi-s tdata
localparam BYTEW = DATAW / 8;   // Bitwidth of axi-s tkeep, tstrb
localparam IDW = 32;			// Bitwidth of axi-s tid
localparam DESTW = 7;		   // Bitwidth of axi-s tdest
localparam USERW = 75;          // Bitwidth of axi-s tuser
localparam IPRECISION = 8;      // Input precision in bits
localparam OPRECISION = 32;     // Output precision in bits
localparam LANES = DATAW / IPRECISION;  // Number of dot-product INT8 lanes
localparam DPES  = LANES;       // Number of dot-product engines 
localparam CLK_PERIOD = 4;
localparam NUM_DPES = 64;
localparam NUM_REPEATS = 100;

reg clk, rst, rx_tvalid, tx_tready;
reg [DATAW-1:0] rx_tdata;
reg [IDW-1:0] rx_tid;
reg [USERW-1:0] rx_tuser;
wire rx_tready, tx_tvalid;
wire [DATAW-1:0] tx_tdata;
wire [USERW-1:0] tx_tuser;
wire [DESTW-1:0] tx_tdest;

mvm # (
	.DATAW(DATAW),
	.BYTEW(BYTEW),
	.IDW(IDW),
	.DESTW(DESTW),
	.USERW(USERW)
) dut (
	.clk(clk),
	.rst(rst),
	.axis_rx_tvalid(rx_tvalid),
	.axis_rx_tdata(rx_tdata),
	.axis_rx_tid(rx_tid),
	.axis_rx_tuser(rx_tuser),
	.axis_rx_tready(rx_tready),	
	.axis_tx_tvalid(tx_tvalid),
	.axis_tx_tdata(tx_tdata),
	.axis_tx_tready(tx_tready),
	.axis_tx_tuser(tx_tuser),
	.axis_tx_tdest(tx_tdest)
);

initial begin
	clk = 1'b0;
	forever begin
		#(CLK_PERIOD/2) clk = !clk;
	end
end

reg [DPES-1:0] onehot;
reg [7:0] i;

initial begin
	rst = 1'b1;
	rx_tvalid = 1'b0;
	rx_tdata = 'd0;
	rx_tid = 'd0;
	rx_tuser = 'd0;
	tx_tready = 1'b0;
	#(CLK_PERIOD);
	
	rst = 1'b0;
	tx_tready = 1'b1;
	
	/***********************INSTRUCTIONS*****************************************************/
	// Send Instruction 0 (Calculate DP of first chunk, first input vector)
	rx_tuser = {64'h0, 2'h0, 9'h0};
	rx_tdata = 32'b0_000000000_000000000_000000000_0_0_0_0;
	rx_tvalid = 1'b1;
	#(CLK_PERIOD);
	
	// Send Instruction 1 (Calculate DP of second chunk, first input vector)
	rx_tuser = {64'h0, 2'h0, 9'h0};
	rx_tdata = 32'b0_000000000_000000001_000000001_0_0_0_0;
	rx_tvalid = 1'b1;
	#(CLK_PERIOD);
	
	// Send Instruction 2 (Calculate DP of third chunk, first input vector)
	rx_tuser = {64'h0, 2'h0, 9'h0};
	rx_tdata = 32'b0_000000000_000000010_000000010_0_0_0_0;
	rx_tvalid = 1'b1;
	#(CLK_PERIOD);
	
	// Send Instruction 3 (Calculate DP of fourth chunk (last), first input vector)
	rx_tuser = {64'h0, 2'h0, 9'h0};
	rx_tdata = 32'b0_000000000_000000011_000000011_1_0_0_0;
	rx_tvalid = 1'b1;
	#(CLK_PERIOD);

	// Send Instruction 4 (Calculate DP of first chunk, second input vector, accumulate)
	rx_tuser = {64'h0, 2'h0, 9'h0};
	rx_tdata = 32'b0_000000000_000000100_000000000_0_0_1_0;
	rx_tvalid = 1'b1;
	#(CLK_PERIOD);
	
	// Send Instruction 5 (Calculate DP of second chunk, second input vector, accumulate)
	rx_tuser = {64'h0, 2'h0, 9'h0};
	rx_tdata = 32'b0_000000000_000000101_000000001_0_0_1_0;
	rx_tvalid = 1'b1;
	#(CLK_PERIOD);
	
	// Send Instruction 6 (Calculate DP of third chunk, second input vector, accumulate)
	rx_tuser = {64'h0, 2'h0, 9'h0};
	rx_tdata = 32'b0_000000000_000000110_000000010_0_0_1_0;
	rx_tvalid = 1'b1;
	#(CLK_PERIOD);
	
	// Send Instruction 7 (Calculate DP of fourth chunk (last), second input vector, accumulate)
	rx_tuser = {64'h0, 2'h0, 9'h0};
	rx_tdata = 32'b0_000000000_000000111_000000011_1_0_1_0;
	rx_tvalid = 1'b1;
	#(CLK_PERIOD);
	
	// Send Instruction 8 (Calculate DP of first chunk, third input vector (last), accumulate, and release IV to node 1)
	rx_tuser = {64'h0, 2'h0, 9'h0};
	rx_tdata = 32'b1_000000001_000001000_000000000_0_1_1_0;
	rx_tvalid = 1'b1;
	#(CLK_PERIOD);
	
	// Send Instruction 9 (Calculate DP of second chunk, third input vector (last), accumulate, and release IV to node 2)
	rx_tuser = {64'h0, 2'h0, 9'h0};
	rx_tdata = 32'b1_000000010_000001001_000000001_0_1_1_0;
	rx_tvalid = 1'b1;
	#(CLK_PERIOD);
	
	// Send Instruction 10 (Calculate DP of third chunk, third input vector (last), accumulate, and release IV to node 1)
	rx_tuser = {64'h0, 2'h0, 9'h0};
	rx_tdata = 32'b1_000000001_000001010_000000010_0_1_1_0;
	rx_tvalid = 1'b1;
	#(CLK_PERIOD);
	
	// Send Instruction 11 (Calculate DP of fourth chunk (last), third input vector (last), accumulate, and release IV to node 2)
	rx_tuser = {64'h0, 2'h0, 9'h0};
	rx_tdata = 32'b1_000000010_000001011_000000011_1_1_1_0;
	rx_tvalid = 1'b1;
	#(CLK_PERIOD);
	/****************************************************************************************/
	
	/***********************MATRIX DATA******************************************************/
	// Send Matrix Data to RFi, chunk 0, first input vector
	rx_tvalid = 1'b1;
	onehot = 64'b1;
	for (i = 1; i <= NUM_DPES; i = i + 1) begin
		rx_tuser = {onehot, 2'h3, 9'h000}; //write to RFi, matrix data op, input vector 0, chunk 0
		rx_tdata = {8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 
					  8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 
					  8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 
					  8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd1, 8'd1, 8'd1}; // [1,1,1]
		onehot = onehot << 1;
		#(CLK_PERIOD);
	end
	
	// Send Matrix Data to RFi, chunk 1, first input vector
	rx_tvalid = 1'b1;
	onehot = 64'b1;
	for (i = 1; i <= NUM_DPES; i = i + 1) begin
		rx_tuser = {onehot, 2'h3, 9'h001}; //write to RFi, matrix data op, input vector 0, chunk 1
		rx_tdata = {8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 
					  8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 
					  8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 
					  8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd2, 8'd2, 8'd2}; // [2,2,2]
		onehot = onehot << 1;
		#(CLK_PERIOD);
	end
	
	// Send Matrix Data to RFi, chunk 2, first input vector
	rx_tvalid = 1'b1;
	onehot = 64'b1;
	for (i = 1; i <= NUM_DPES; i = i + 1) begin
		rx_tuser = {onehot, 2'h3, 9'h002}; //write to RFi, matrix data op, input vector 0, chunk 2
		rx_tdata = {8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 
					  8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 
					  8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 
					  8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd3, 8'd3, 8'd3}; // [3,3,3]
		onehot = onehot << 1;
		#(CLK_PERIOD);
	end
	
	// Send Matrix Data to RFi, chunk 3, first input vector
	rx_tvalid = 1'b1;
	onehot = 64'b1;
	for (i = 1; i <= NUM_DPES; i = i + 1) begin
		rx_tuser = {onehot, 2'h3, 9'h003}; //write to RFi, matrix data op, input vector 0, chunk 3
		rx_tdata = {8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 
					  8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 
					  8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 
					  8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd4, 8'd4, 8'd4}; // [4,4,4]
		onehot = onehot << 1;
		#(CLK_PERIOD);
	end
	
	// Send Matrix Data to RFi, chunk 0, second input vector
	rx_tvalid = 1'b1;
	onehot = 64'b1;
	for (i = 1; i <= NUM_DPES; i = i + 1) begin
		rx_tuser = {onehot, 2'h3, 9'h004}; //write to RFi, matrix data op, input vector 1, chunk 0
		rx_tdata = {8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 
					  8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 
					  8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 
					  8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd1, 8'd1, 8'd1}; // [1,1,1]
		onehot = onehot << 1;
		#(CLK_PERIOD);
	end
	
	// Send Matrix Data to RFi, chunk 1, second input vector
	rx_tvalid = 1'b1;
	onehot = 64'b1;
	for (i = 1; i <= NUM_DPES; i = i + 1) begin
		rx_tuser = {onehot, 2'h3, 9'h005}; //write to RFi, matrix data op, input vector 1, chunk 1
		rx_tdata = {8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 
					  8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 
					  8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 
					  8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd2, 8'd2, 8'd2}; // [2,2,2]
		onehot = onehot << 1;
		#(CLK_PERIOD);
	end
	
	// Send Matrix Data to RFi, chunk 2, second input vector
	rx_tvalid = 1'b1;
	onehot = 64'b1;
	for (i = 1; i <= NUM_DPES; i = i + 1) begin
		rx_tuser = {onehot, 2'h3, 9'h006}; //write to RFi, matrix data op, input vector 1, chunk 2
		rx_tdata = {8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 
					  8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 
					  8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 
					  8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd3, 8'd3, 8'd3}; // [3,3,3]
		onehot = onehot << 1;
		#(CLK_PERIOD);
	end
	
	// Send Matrix Data to RFi, chunk 3, second input vector
	rx_tvalid = 1'b1;
	onehot = 64'b1;
	for (i = 1; i <= NUM_DPES; i = i + 1) begin
		rx_tuser = {onehot, 2'h3, 9'h007}; //write to RFi, matrix data op, input vector 1, chunk 3
		rx_tdata = {8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 
					  8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 
					  8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 
					  8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd4, 8'd4, 8'd4}; // [4,4,4]
		onehot = onehot << 1;
		#(CLK_PERIOD);
	end

	// Send Matrix Data to RFi, chunk 0, third input vector
	rx_tvalid = 1'b1;
	onehot = 64'b1;
	for (i = 1; i <= NUM_DPES; i = i + 1) begin
		rx_tuser = {onehot, 2'h3, 9'h008}; //write to RFi, matrix data op, input vector 2, chunk 0
		rx_tdata = {8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 
					  8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 
					  8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 
					  8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd1, 8'd1, 8'd1}; // [1,1,1]
		onehot = onehot << 1;
		#(CLK_PERIOD);
	end
	
	// Send Matrix Data to RFi, chunk 1, third input vector
	rx_tvalid = 1'b1;
	onehot = 64'b1;
	for (i = 1; i <= NUM_DPES; i = i + 1) begin
		rx_tuser = {onehot, 2'h3, 9'h009}; //write to RFi, matrix data op, input vector 2, chunk 1
		rx_tdata = {8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 
					  8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 
					  8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 
					  8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd2, 8'd2, 8'd2}; // [2,2,2]
		onehot = onehot << 1;
		#(CLK_PERIOD);
	end
	
	// Send Matrix Data to RFi, chunk 2, third input vector
	rx_tvalid = 1'b1;
	onehot = 64'b1;
	for (i = 1; i <= NUM_DPES; i = i + 1) begin
		rx_tuser = {onehot, 2'h3, 9'h00a}; //write to RFi, matrix data op, input vector 2, chunk 2
		rx_tdata = {8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 
					  8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 
					  8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 
					  8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd3, 8'd3, 8'd3}; // [3,3,3]
		onehot = onehot << 1;
		#(CLK_PERIOD);
	end
	
	// Send Matrix Data to RFi, chunk 3, third input vector
	rx_tvalid = 1'b1;
	onehot = 64'b1;
	for (i = 1; i <= NUM_DPES; i = i + 1) begin
		rx_tuser = {onehot, 2'h3, 9'h00b}; //write to RFi, matrix data op, input vector 2, chunk 3
		rx_tdata = {8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 
					  8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 
					  8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 
					  8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd4, 8'd4, 8'd4}; // [4,4,4]
		onehot = onehot << 1;
		#(CLK_PERIOD);
	end
	/****************************************************************************************/

	$stop();

	/***********************INPUT VECTORS****************************************************/
	for (i = 0; i < NUM_REPEATS; i = i + 1) begin
		// Send Input Vector 0
		rx_tuser = {64'h0, 2'h2, 9'h0};
		rx_tdata = {8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 
					  8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 
					  8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 
					  8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd1, 8'd1, 8'd1}; // [1,1,1]
		rx_tvalid = 1'b1;
		#(CLK_PERIOD);
		
		// Send Input Vector 1
		rx_tuser = {64'h0, 2'h2, 9'h0};
		rx_tdata = {8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 
					  8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 
					  8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 
					  8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd2, 8'd2, 8'd2}; // [2,2,2]
		rx_tvalid = 1'b1;
		#(CLK_PERIOD);

		// Send Input Vector 2
		rx_tuser = {64'h0, 2'h2, 9'h0};
		rx_tdata = {8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 
					  8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 
					  8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 
					  8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd3, 8'd3, 8'd3}; // [3,3,3]
		rx_tvalid = 1'b1;
		#(CLK_PERIOD);
	end
	/****************************************************************************************/

	rx_tvalid = 1'b0;
	/*
	#(10*CLK_PERIOD); // Stall pipeline to test reduction vectors
	*/
	/***********************REDUCTION VECTORS************************************************/
	/*// Send Reduction Vector 0
	rx_tuser = {64'h0, 2'h1, 9'h0};
	rx_tdata = {8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 
				  8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 
				  8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 
				  8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1}; // all 1s
	rx_tvalid = 1'b1;
	#(CLK_PERIOD);
	
	// Send Reduction Vector 1
	rx_tuser = {64'h0, 2'h1, 9'h0};
	rx_tdata = {8'd2, 8'd2, 8'd2, 8'd2, 8'd2, 8'd2, 8'd2, 8'd2, 8'd2, 8'd2, 8'd2, 8'd2, 8'd2, 8'd2, 8'd2, 8'd2, 
				  8'd2, 8'd2, 8'd2, 8'd2, 8'd2, 8'd2, 8'd2, 8'd2, 8'd2, 8'd2, 8'd2, 8'd2, 8'd2, 8'd2, 8'd2, 8'd2, 
				  8'd2, 8'd2, 8'd2, 8'd2, 8'd2, 8'd2, 8'd2, 8'd2, 8'd2, 8'd2, 8'd2, 8'd2, 8'd2, 8'd2, 8'd2, 8'd2, 
				  8'd2, 8'd2, 8'd2, 8'd2, 8'd2, 8'd2, 8'd2, 8'd2, 8'd2, 8'd2, 8'd2, 8'd2, 8'd2, 8'd2, 8'd2, 8'd2}; // all 2s
	rx_tvalid = 1'b1;
	#(CLK_PERIOD);
	
	// Send Reduction Vector 2
	rx_tuser = {64'h0, 2'h1, 9'h0};
	rx_tdata = {8'd3, 8'd3, 8'd3, 8'd3, 8'd3, 8'd3, 8'd3, 8'd3, 8'd3, 8'd3, 8'd3, 8'd3, 8'd3, 8'd3, 8'd3, 8'd3, 
				  8'd3, 8'd3, 8'd3, 8'd3, 8'd3, 8'd3, 8'd3, 8'd3, 8'd3, 8'd3, 8'd3, 8'd3, 8'd3, 8'd3, 8'd3, 8'd3, 
				  8'd3, 8'd3, 8'd3, 8'd3, 8'd3, 8'd3, 8'd3, 8'd3, 8'd3, 8'd3, 8'd3, 8'd3, 8'd3, 8'd3, 8'd3, 8'd3, 
				  8'd3, 8'd3, 8'd3, 8'd3, 8'd3, 8'd3, 8'd3, 8'd3, 8'd3, 8'd3, 8'd3, 8'd3, 8'd3, 8'd3, 8'd3, 8'd3}; // all 3s
	rx_tvalid = 1'b1;
	#(CLK_PERIOD);
	
	// Send Reduction Vector 3
	rx_tuser = {64'h0, 2'h1, 9'h0};
	rx_tdata = {8'd4, 8'd4, 8'd4, 8'd4, 8'd4, 8'd4, 8'd4, 8'd4, 8'd4, 8'd4, 8'd4, 8'd4, 8'd4, 8'd4, 8'd4, 8'd4, 
				  8'd4, 8'd4, 8'd4, 8'd4, 8'd4, 8'd4, 8'd4, 8'd4, 8'd4, 8'd4, 8'd4, 8'd4, 8'd4, 8'd4, 8'd4, 8'd4, 
				  8'd4, 8'd4, 8'd4, 8'd4, 8'd4, 8'd4, 8'd4, 8'd4, 8'd4, 8'd4, 8'd4, 8'd4, 8'd4, 8'd4, 8'd4, 8'd4, 
				  8'd4, 8'd4, 8'd4, 8'd4, 8'd4, 8'd4, 8'd4, 8'd4, 8'd4, 8'd4, 8'd4, 8'd4, 8'd4, 8'd4, 8'd4, 8'd4}; // all 4s
	rx_tvalid = 1'b1;
	#(CLK_PERIOD);*/
	/****************************************************************************************/
	
	rx_tvalid = 1'b0;
	#(5*CLK_PERIOD);
end

reg passing;
integer count;
integer repeats;

initial begin
	passing = 1;
	count = 0;
	repeats = 0;
	while (1'b1) begin
		if (tx_tvalid) begin
			if 			(count == 0 && (tx_tdata !== {NUM_DPES{8'h12}} || tx_tuser[10:9] !== 2'h2 || tx_tdest !== 1)) begin
				passing = 0;
			end else if (count == 1 && (tx_tdata !== {NUM_DPES{8'h24}} || tx_tuser[10:9] !== 2'h2 || tx_tdest !== 2)) begin
				passing = 0;
			end else if (count == 2 && (tx_tdata !== {NUM_DPES{8'h36}} || tx_tuser[10:9] !== 2'h2 || tx_tdest !== 1)) begin
				passing = 0;
			end else if (count == 3 && (tx_tdata !== {NUM_DPES{8'h48}} || tx_tuser[10:9] !== 2'h2 || tx_tdest !== 2)) begin
				passing = 0;
			end
			count = count + 1;
		end
		if (count == 4) begin
			repeats = repeats + 1;
			count = 0;
			
			if (repeats == NUM_REPEATS) begin
				if (passing) begin
					$display("Simulation PASSED!");
				end else begin
					$display("Simulation FAILED!");
				end
				$stop();
			end
		end
		#(CLK_PERIOD);
	end
end

endmodule