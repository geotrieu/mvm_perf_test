module collector # (
	parameter DATAW = 512,
	parameter BYTEW = 8,   		   // Bitwidth of axi-s tkeep, tstrb
	parameter IDW = 32,            // Bitwidth of axi-s tid
	parameter DESTW = 7,		   // Bitwidth of axi-s tdest
	parameter USERW = 75,          // Bitwidth of axi-s tuser
	parameter DATAUSERW = DATAW + USERW
) (
   input clk,
   input rst,
   
	input data_fifo_ren,
	
	input  axis_rx_tvalid,
	input  [DATAUSERW-1:0] axis_rx_tdata,
	input  [BYTEW-1:0] axis_rx_tstrb,
	input  [BYTEW-1:0] axis_rx_tkeep,
	input  [IDW-1:0] axis_rx_tid,
	input  [DESTW-1:0] axis_rx_tdest,
	input  [USERW-1:0] axis_rx_tuser,
	input  axis_rx_tlast,
	output logic axis_rx_tready,
	
   output logic [DATAW-1:0] data_fifo_rdata,
   output logic data_fifo_rdy
);

	logic [DATAW-1:0] data_fifo_wdata_signal;
	logic data_fifo_wen_signal, data_fifo_full_signal, data_fifo_empty_signal, data_fifo_almost_full_signal;

	// Hook up unused Rx signals to dummy registers to avoid being synthesized away
	(*noprune*) reg [BYTEW-1:0] dummy_axis_rx_tstrb;
	(*noprune*) reg [BYTEW-1:0] dummy_axis_rx_tkeep;
	(*noprune*) reg [DESTW-1:0] dummy_axis_rx_tdest;
	(*noprune*) reg [USERW-1:0] dummy_axis_rx_tuser;
	(*noprune*) reg [IDW-1:0] dummy_axis_rx_tid;
	always @ (posedge clk) begin
		dummy_axis_rx_tstrb <= axis_rx_tstrb;
		dummy_axis_rx_tkeep <= axis_rx_tkeep;
		dummy_axis_rx_tdest <= axis_rx_tdest;
		dummy_axis_rx_tuser <= axis_rx_tuser;
		dummy_axis_rx_tid <= axis_rx_tid;
	end
	
	fifo #(
		.DATAW(DATAW),
		.DEPTH(64)
	) data_fifo (
	   .clk,
	   .rst,
	   .push(data_fifo_wen_signal),
	   .idata(data_fifo_wdata_signal),
	   .pop(data_fifo_ren),
	   .odata(data_fifo_rdata),
	   .empty(data_fifo_empty_signal),
	   .full(data_fifo_full_signal),
	   .almost_full(data_fifo_almost_full_signal)
   );
 
   always @(*) begin
		if (rst) begin
			axis_rx_tready = 1'b0;
			data_fifo_rdy = 1'b0;
		end else begin
			axis_rx_tready = ~data_fifo_almost_full_signal;
			data_fifo_rdy = ~data_fifo_empty_signal;

			if (axis_rx_tvalid && axis_rx_tready) begin
				data_fifo_wen_signal = 1'b1;
				data_fifo_wdata_signal = axis_rx_tdata[DATAW-1:0];
			end else begin
				data_fifo_wen_signal = 1'b0;
			end
		end
	end
endmodule
