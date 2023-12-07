module dispatcher # (
	parameter DATAW = 512,
	parameter BYTEW = 8,   		   // Bitwidth of axi-s tkeep, tstrb
	parameter IDW = 32,            // Bitwidth of axi-s tid
	parameter DESTW = 7,		   // Bitwidth of axi-s tdest
	parameter USERW = 75,          // Bitwidth of axi-s tuser
	parameter DESTNODE,
	parameter DATAUSERW = DATAW + USERW
) (
   input clk,
   input rst,
   
	input data_fifo_wen,
	input data_last,
	
	output  logic axis_tx_tvalid,
	output  logic [DATAUSERW-1:0] axis_tx_tdata,
	output  logic [BYTEW-1:0] axis_tx_tstrb,
	output  logic [BYTEW-1:0] axis_tx_tkeep,
	output  logic [IDW-1:0] axis_tx_tid,
	output  logic [DESTW-1:0] axis_tx_tdest,
	output  logic [USERW-1:0] axis_tx_tuser,
	output  logic axis_tx_tlast,
	input   axis_tx_tready,
	
   input [DATAW-1:0] data_fifo_wdata,
   output logic data_fifo_rdy
);

	logic [DATAW-1:0] tdata;
	logic [USERW-1:0] tuser;

	logic [DATAW-1:0] data_fifo_rdata_signal;
	logic data_fifo_ren_signal, data_fifo_full_signal, data_fifo_empty_signal, data_fifo_almost_full_signal;
	
	fifo #(
		.DATAW(DATAW),
		.DEPTH(64)
	) data_fifo (
	   .clk,
	   .rst,
	   .push(data_fifo_wen),
	   .idata(data_fifo_wdata),
	   .pop(data_fifo_ren_signal),
	   .odata(data_fifo_rdata_signal),
	   .empty(data_fifo_empty_signal),
	   .full(data_fifo_full_signal),
	   .almost_full(data_fifo_almost_full_signal)
   );
 
   always @(*) begin
		if (rst) begin
			axis_tx_tvalid = 1'b0;
			data_fifo_rdy = 1'b0;
			tdata = 0;
			tuser = 0;
		end else begin
			if (~data_fifo_empty_signal) begin
				axis_tx_tvalid = 1'b1;
				tdata = data_fifo_rdata_signal;
				tuser = 2'h2 << 9;
				axis_tx_tid = 0;
				axis_tx_tdest = DESTNODE;
			end else begin
				axis_tx_tvalid = 1'b0;
			end

			data_fifo_ren_signal = axis_tx_tvalid && axis_tx_tready;
			data_fifo_rdy = ~data_fifo_almost_full_signal;
		end
	end

	always_ff @(posedge clk) begin
		if (rst) begin
			axis_tx_tlast <= 1'b0;
		end else begin
			axis_tx_tlast <= data_last;
		end
	end
	
	assign axis_tx_tdata = {tuser, tdata};

	// Hook up rest of Tx signals to dummy values to avoid optimizing them out
	assign axis_tx_tstrb = tdata[BYTEW-1:0];
	assign axis_tx_tkeep = tdata[2*BYTEW-1:BYTEW];
	assign axis_tx_tuser = tdata[USERW-1:0];
endmodule
