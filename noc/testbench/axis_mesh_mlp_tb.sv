`timescale 1ns / 1ps

`include "config.vh"

module axis_mesh_mlp_tb();
    localparam NUM_ROWS = 4;
    localparam NUM_COLS = 4;
	localparam ACTUAL_DATAW = 512; // DATAW used in MVM
	localparam ACTUAL_USERW = 75; // USERW used in MVM
    localparam DATA_WIDTH = ACTUAL_DATAW + ACTUAL_USERW; // This NoC implementation does not supprot tuser, append to top of tdata
    localparam TDEST_WIDTH = 4;
    localparam TID_WIDTH = 2;

    localparam SERIALIZATION_FACTOR = 1;
    localparam CLKCROSS_FACTOR = 2;

    localparam SINGLE_CLOCK = ((CLKCROSS_FACTOR == 1) ? 1 : 0);

    localparam USR_CLK_PERIOD = real'(10);
    localparam NOC_CLK_PERIOD = USR_CLK_PERIOD / CLKCROSS_FACTOR;

    localparam USR_CLK_SWITCH = USR_CLK_PERIOD / 2;
    localparam NOC_CLK_SWITCH = NOC_CLK_PERIOD / 2;
	 
	 localparam string PROJECT_DIR = `PROJECT_DIR;
	 localparam string ROUTING_TABLE_PREFIX = $sformatf("%s%s", PROJECT_DIR, "routing_tables/mesh_4x4/");

    logic clk, clk_noc, rst_n;
	 
	 logic collector_fifo_ren, collector_fifo_rdy;
	 logic [ACTUAL_DATAW - 1: 0] collector_fifo_rdata;

	 logic dispatcher_fifo_wen, dispatcher_fifo_rdy;
	 logic [ACTUAL_DATAW - 1: 0] dispatcher_fifo_wdata;

    logic                       axis_in_tvalid  [NUM_ROWS][NUM_COLS];
    logic                       axis_in_tready  [NUM_ROWS][NUM_COLS];
    logic [DATA_WIDTH - 1 : 0]  axis_in_tdata   [NUM_ROWS][NUM_COLS];
    logic                       axis_in_tlast   [NUM_ROWS][NUM_COLS];
    logic [TDEST_WIDTH - 1 : 0] axis_in_tdest   [NUM_ROWS][NUM_COLS];
    logic [TID_WIDTH - 1 : 0]   axis_in_tid     [NUM_ROWS][NUM_COLS];

    logic                       axis_out_tvalid [NUM_ROWS][NUM_COLS];
    logic                       axis_out_tready [NUM_ROWS][NUM_COLS];
    logic [DATA_WIDTH - 1 : 0]  axis_out_tdata  [NUM_ROWS][NUM_COLS];
    logic                       axis_out_tlast  [NUM_ROWS][NUM_COLS];
    logic [TDEST_WIDTH - 1 : 0] axis_out_tdest  [NUM_ROWS][NUM_COLS];
    logic [TID_WIDTH - 1 : 0]   axis_out_tid    [NUM_ROWS][NUM_COLS];

    initial begin
        clk = 1'b0;
        forever begin
            #USR_CLK_SWITCH clk = ~clk;
        end
    end

    initial begin
        clk_noc = 1'b1;
        forever begin
            #NOC_CLK_SWITCH clk_noc = ~clk_noc;
        end
    end

    initial begin
		rst_n = 1'b0;
		dispatcher_fifo_wen = 1'b0;
		dispatcher_fifo_wdata = 0;
		collector_fifo_ren = 1'b0;
		for (int r = 0; r < NUM_ROWS; r++) begin
			for (int c = 0; c < NUM_COLS; c++) begin
				axis_in_tdata[r][c] = 0;
				axis_in_tvalid[r][c] = 1'b0;
				axis_in_tlast[r][c] = 1'b0;
				axis_in_tdest[r][c] = 0;
				axis_in_tid[r][c] = 0;
			end
		end
		@(negedge clk);
		rst_n = 1'b1;
		collector_fifo_ren = 1'b1;
		@(negedge clk);
		// start
		send_instruction(32'b1_000000001_000000000_000000000_0_1_0_0, 0, 1'b0);
		send_instruction(32'b1_000000001_000000001_000000001_0_1_0_0, 0, 1'b0);
		send_instruction(32'b1_000000001_000000010_000000010_0_1_0_0, 0, 1'b0);
		send_instruction(32'b1_000000001_000000011_000000011_1_1_0_0, 0, 1'b1);
		send_weight({8'd1, 8'd1, 8'd1}, 0, 0, 0, 1'b0);
		send_weight({8'd2, 8'd2, 8'd2}, 0, 1, 0, 1'b0);
		send_weight({8'd3, 8'd3, 8'd3}, 0, 2, 0, 1'b0);
		send_weight({8'd4, 8'd4, 8'd4}, 0, 3, 0, 1'b1);
		
		while (~dispatcher_fifo_rdy) begin
			@(negedge clk);
		end
		dispatcher_fifo_wdata = {8'd1, 8'd1, 8'd1};
		dispatcher_fifo_wen = 1'b1;
		@(negedge clk);
		dispatcher_fifo_wen = 1'b0;
		@(negedge clk);
    end
	
	integer count;
	bit passing;
	
	initial begin
		// check
		count = 0;
		passing = 1;
		forever begin
			@(negedge clk);
			if (collector_fifo_ren && collector_fifo_rdy) begin
				$display("Received: %d", collector_fifo_rdata);
				case (++count)
					1: if (collector_fifo_rdata !== 64'h3) passing = 0;
					2: if (collector_fifo_rdata !== 64'h6) passing = 0;
					3: if (collector_fifo_rdata !== 64'h9) passing = 0;
					4: if (collector_fifo_rdata !== 64'hc) passing = 0;
				endcase
				
				if (count == 4) begin
					if (passing) $display("PASS");
					else $display("FAIL");
					$finish;
				end
			end
		end
		@(negedge clk);
	end

	 mvm #(
		  .DATAW(ACTUAL_DATAW),         // Bitwidth of axi-s tdata (without tuser appended)
		  .IDW(TID_WIDTH),            // Bitwidth of axi-s tid
	     .DESTW(TDEST_WIDTH)		   // Bitwidth of axi-s tdest
	 ) mvm_inst (
	     .clk,
	     .rst(~rst_n),
	     .axis_rx_tvalid(axis_out_tvalid[0][0]),
	     .axis_rx_tdata(axis_out_tdata[0][0]),
	     .axis_rx_tid(axis_out_tid[0][0]),
	     .axis_rx_tdest(axis_out_tdest[0][0]),
	     .axis_rx_tready(axis_out_tready[0][0]),
	     .axis_tx_tvalid(axis_in_tvalid[0][0]),
		  .axis_tx_tdata(axis_in_tdata[0][0]),
	     .axis_tx_tid(axis_in_tid[0][0]),
	     .axis_tx_tdest(axis_in_tdest[0][0]),
	     .axis_tx_tready(axis_in_tready[0][0])
	 );
	 
	 collector #(
		  .DATAW(ACTUAL_DATAW),         // Bitwidth of axi-s tdata
		  .IDW(TID_WIDTH),            // Bitwidth of axi-s tid
	     .DESTW(TDEST_WIDTH)		   // Bitwidth of axi-s tdest
    ) collector_inst (
        .clk,
        .rst(~rst_n),
	     .data_fifo_ren(collector_fifo_ren),
		  .axis_rx_tvalid(axis_out_tvalid[0][1]),
	     .axis_rx_tdata(axis_out_tdata[0][1][ACTUAL_DATAW-1:0]),
	     .axis_rx_tid(axis_out_tid[0][1]),
	     .axis_rx_tdest(axis_out_tdest[0][1]),
	     .axis_rx_tready(axis_out_tready[0][1]),
	     .data_fifo_rdata(collector_fifo_rdata),
        .data_fifo_rdy(collector_fifo_rdy)
    );

	dispatcher #(
		  .DATAW(ACTUAL_DATAW),         // Bitwidth of axi-s tdata
		  .IDW(TID_WIDTH),            // Bitwidth of axi-s tid
	     .DESTW(TDEST_WIDTH),		   // Bitwidth of axi-s tdest
		 .DESTNODE(0)
    ) dispatcher_inst (
        .clk,
        .rst(~rst_n),
	     .data_fifo_wen(dispatcher_fifo_wen),
		  .axis_tx_tvalid(axis_in_tvalid[0][2]),
	     .axis_tx_tdata(axis_in_tdata[0][2]),
	     .axis_tx_tid(axis_in_tid[0][2]),
	     .axis_tx_tdest(axis_in_tdest[0][2]),
	     .axis_tx_tready(axis_in_tready[0][2]),
	     .data_fifo_wdata(dispatcher_fifo_wdata),
         .data_fifo_rdy(dispatcher_fifo_rdy)
    );

    axis_mesh #(
        .NUM_ROWS                   (NUM_ROWS),
        .NUM_COLS                   (NUM_COLS),
        .PIPELINE_LINKS             (0),

        .TDEST_WIDTH                (TDEST_WIDTH),
        .TDATA_WIDTH                (DATA_WIDTH),
        .SERIALIZATION_FACTOR       (SERIALIZATION_FACTOR),
        .CLKCROSS_FACTOR            (CLKCROSS_FACTOR),
        .SINGLE_CLOCK               (SINGLE_CLOCK),
        .SERDES_IN_BUFFER_DEPTH     (4),
        .SERDES_OUT_BUFFER_DEPTH    (4),
        .SERDES_EXTRA_SYNC_STAGES   (0),

        .FLIT_BUFFER_DEPTH          (8),
        .ROUTING_TABLE_PREFIX       (ROUTING_TABLE_PREFIX),
        .ROUTER_PIPELINE_OUTPUT     (1),
        .ROUTER_DISABLE_SELFLOOP    (0),
        .ROUTER_FORCE_MLAB          (0)
    ) dut (
        .clk_noc(clk_noc),
        .clk_usr(clk),
        .rst_n,

        .axis_in_tvalid ,
        .axis_in_tready ,
        .axis_in_tdata  ,
        .axis_in_tlast  ,
        .axis_in_tid    ,
        .axis_in_tdest  ,

        .axis_out_tvalid,
        .axis_out_tready,
        .axis_out_tdata ,
        .axis_out_tlast ,
        .axis_out_tid   ,
        .axis_out_tdest
    );
	 
	 task send_instruction;
		input [31:0] instruction;
		input node;
		input last;
		begin
			while (~axis_in_tready[1][0]) begin
				@(negedge clk);
			end
			axis_in_tdata[1][0][31:0] = instruction;
			axis_in_tdata[1][0][DATA_WIDTH-1:ACTUAL_DATAW] = 1'b0 << 9;
			axis_in_tdest[1][0] = node;
			axis_in_tvalid[1][0] = 1'b1;
			axis_in_tlast[1][0] = last;
			@(negedge clk);
			axis_in_tdata[1][0] = 0;
			axis_in_tvalid[1][0] = 1'b0;
			axis_in_tlast[1][0] = 1'b0;
		end
	 endtask
	 
	 task send_weight;
		input [ACTUAL_DATAW-1:0] data;
		input int dpe;
		input [8:0] rf_addr;
		input int node;
		input last;
		begin
			bit [63:0] rf_en;
			rf_en = 1'b1 << dpe;
			while (~axis_in_tready[2][0]) begin
				@(negedge clk);
			end
			axis_in_tdata[2][0][ACTUAL_DATAW-1:0] = data;
			axis_in_tdata[2][0][DATA_WIDTH-1:ACTUAL_DATAW] = (rf_en << 11) | (2'h3 << 9) | rf_addr;
			axis_in_tdest[2][0] = node;
			axis_in_tvalid[2][0] = 1'b1;
			axis_in_tlast[2][0] = last;
			@(negedge clk);
			axis_in_tdata[2][0] = 0;
			axis_in_tvalid[2][0] = 1'b0;
			axis_in_tlast[2][0] = 1'b0;
		end
	 endtask

endmodule: axis_mesh_mlp_tb