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
    localparam CLKCROSS_FACTOR = 4;

    localparam SINGLE_CLOCK = ((CLKCROSS_FACTOR == 1) ? 1 : 0);

    localparam USR_CLK_PERIOD = real'(5);
    localparam NOC_CLK_PERIOD = USR_CLK_PERIOD / CLKCROSS_FACTOR;

    localparam USR_CLK_SWITCH = USR_CLK_PERIOD / 2;
    localparam NOC_CLK_SWITCH = NOC_CLK_PERIOD / 2;
	 
	 localparam string PROJECT_DIR = `PROJECT_DIR;
	 localparam string ROUTING_TABLE_PREFIX = $sformatf("%s%s", PROJECT_DIR, "routing_tables/mesh_4x4/");

	 localparam LANES = 64;
	 localparam IPRECISION = 8;

	// Test Compiler MIF Set
	 /*localparam DPES = 2;
	 localparam string INST_MIFS = $sformatf("%s%s", PROJECT_DIR, "test_compiler/inst_mifs/");
	 localparam string WEIGHT_MIFS = $sformatf("%s%s", PROJECT_DIR, "test_compiler/weight_mifs/preload/");
	 localparam string INPUT_MIFS = $sformatf("%s%s", PROJECT_DIR, "test_compiler/input_mifs/");
	 localparam string GOLDEN_OUTPUT_MIF = $sformatf("%s%s", PROJECT_DIR, "test_compiler/golden_outputs.mif");
	 localparam NUM_LAYERS = 2;
	 localparam integer NUM_MVMS[NUM_LAYERS] = {2,1};
	 localparam NUM_MVMS_FIRST_LAYER = NUM_MVMS[0];
	 localparam MAX_MVMS = 2;
	 localparam integer DISPATCHER_NODE_IDS[NUM_MVMS[0]] = {0,1};
	 localparam integer MVM_NODE_IDS[NUM_LAYERS][MAX_MVMS] = {{3,4},{5,99}};
	 localparam WEIGHT_LOADER_NODE_ID = 13;
	 localparam INST_LOADER_NODE_ID = 14;
	 localparam COLLECTOR_NODE_ID = 15;*/
	
	// Production Compiler MIF Set
	 localparam DPES = 64;
	 localparam string INST_MIFS = $sformatf("%s%s", PROJECT_DIR, "compiler/inst_mifs/");
	 localparam string WEIGHT_MIFS = $sformatf("%s%s", PROJECT_DIR, "compiler/weight_mifs/preload/");
	 localparam string INPUT_MIFS = $sformatf("%s%s", PROJECT_DIR, "compiler/input_mifs/");
	 localparam string GOLDEN_OUTPUT_MIF = $sformatf("%s%s", PROJECT_DIR, "compiler/golden_outputs.mif");
	 localparam NUM_LAYERS = 4;
	 localparam integer NUM_MVMS[NUM_LAYERS] = {3,3,2,2};
	 localparam NUM_MVMS_FIRST_LAYER = NUM_MVMS[0];
	 localparam MAX_MVMS = 3;
	 localparam integer DISPATCHER_NODE_IDS[NUM_MVMS[0]] = {4,5,6};
	 localparam integer MVM_NODE_IDS[NUM_LAYERS][MAX_MVMS] = {{2,1,9},{14,11,12},{10,3,99},{8,7,99}};
	 localparam WEIGHT_LOADER_NODE_ID = 13;
	 localparam INST_LOADER_NODE_ID = 15;
	 localparam COLLECTOR_NODE_ID = 0;

    logic clk, clk_noc, rst_n;
	 
	 logic collector_fifo_ren, collector_fifo_rdy;
	 logic [ACTUAL_DATAW - 1: 0] collector_fifo_rdata;

	 logic dispatcher_fifo_wen[NUM_MVMS_FIRST_LAYER];
	 logic dispatcher_last[NUM_MVMS_FIRST_LAYER];
	 logic dispatcher_fifo_rdy[NUM_MVMS_FIRST_LAYER];
	 logic [ACTUAL_DATAW - 1: 0] dispatcher_fifo_wdata[NUM_MVMS_FIRST_LAYER];

	 logic [ACTUAL_DATAW-1:0] test_inputs [NUM_MVMS_FIRST_LAYER][];
	 int written_inputs[NUM_MVMS_FIRST_LAYER];
	 bit still_have_inputs_to_feed;

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
		for (int dispatcher = 0; dispatcher < NUM_MVMS_FIRST_LAYER; dispatcher++) begin
			parse_inputs($sformatf("%sinputs_mvm%0d.mif", INPUT_MIFS, dispatcher), test_inputs[dispatcher]);
			written_inputs[dispatcher] = 0;
			dispatcher_fifo_wen[dispatcher] = 1'b0;
			dispatcher_fifo_wdata[dispatcher] = 0;
		end
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
		for (int layer = 0; layer < NUM_LAYERS; layer++) begin
			for (int mvm = 0; mvm < NUM_MVMS[layer]; mvm++) begin
				parse_send_instructions($sformatf("%slayer%0d_mvm%0d.mif", INST_MIFS, layer, mvm), MVM_NODE_IDS[layer][mvm]);
			end
		end
		$display("Done loading Instructions");

		/*for (int layer = 0; layer < NUM_LAYERS; layer++) begin
			for (int mvm = 0; mvm < NUM_MVMS[layer]; mvm++) begin
				for (int dpe = 0; dpe < DPES; dpe++) begin
					$display("Loading: layer%0d_mvm%0d_dot%0d.mif", layer, mvm, dpe);
					parse_send_weights($sformatf("%slayer%0d_mvm%0d_dot%0d.mif", WEIGHT_MIFS, layer, mvm, dpe), dpe, MVM_NODE_IDS[layer][mvm]);
				end
			end
		end
		$display("Done loading Weights");*/

		$stop();

		still_have_inputs_to_feed = 1'b1;
		while (still_have_inputs_to_feed) begin
			for (int dispatcher = 0; dispatcher < NUM_MVMS_FIRST_LAYER; dispatcher++) begin
				if (written_inputs[dispatcher] < test_inputs[dispatcher].size()) begin
					send_input(test_inputs[dispatcher][written_inputs[dispatcher]], dispatcher, written_inputs[dispatcher] == (test_inputs[dispatcher].size() - 1));
					written_inputs[dispatcher]++;
				end
				still_have_inputs_to_feed = 1'b0;
				for (int i = 0; i < NUM_MVMS_FIRST_LAYER; i++) begin
					still_have_inputs_to_feed = still_have_inputs_to_feed || (written_inputs[i] < test_inputs[i].size());
				end
			end
		end
		$display("Done sending input vectors");
		@(negedge clk);
    end
	
	integer count;
	bit passing;
	integer data_file, scan_file;
	logic [IPRECISION - 1:0] golden_output;
	
	initial begin
		// check
		count = 0;
		passing = 1;
		data_file = $fopen(GOLDEN_OUTPUT_MIF, "r");
		forever begin
			@(negedge clk);
			if (collector_fifo_ren && collector_fifo_rdy) begin
				//$display("Vector Results: (dut result : golden result)");
				for (int dpe = 0; dpe < DPES; dpe++) begin
					scan_file = $fscanf(data_file, "%d ", golden_output);

					//$display("%0d : %0d", collector_fifo_rdata[dpe*IPRECISION +: IPRECISION], golden_output);
					if (collector_fifo_rdata[dpe*IPRECISION +: IPRECISION] !== golden_output) passing = 0;
				end
				scan_file = $fscanf(data_file, "\n");
				
				if ($feof(data_file)) begin
					if (passing) $display("PASS");
					else $display("FAIL");
					$stop();
				end
			end
		end
		@(negedge clk);
	end

	generate begin: mvm_gen
		genvar layer_id, mvm_id;
		for (layer_id = 0; layer_id < NUM_LAYERS; layer_id++) begin: generate_layers
			for (mvm_id = 0; mvm_id < NUM_MVMS[layer_id]; mvm_id++) begin: generate_mvms
				localparam row = node_r(MVM_NODE_IDS[layer_id][mvm_id]);
				localparam col = node_c(MVM_NODE_IDS[layer_id][mvm_id]);
				localparam string weight_hex_prefix = $sformatf("%slayer%0d_mvm%0d", WEIGHT_MIFS, layer_id, mvm_id);
			
				mvm #(
					.DATAW(ACTUAL_DATAW),         // Bitwidth of axi-s tdata (without tuser appended)
					.IDW(TID_WIDTH),            // Bitwidth of axi-s tid
					.DESTW(TDEST_WIDTH),		   // Bitwidth of axi-s tdest
					.MEM_INIT_FILE_PREFIX(weight_hex_prefix),
					.DPES(DPES)
				) mvm_inst (
					.clk,
					.rst(~rst_n),
					.axis_rx_tvalid(axis_out_tvalid[row][col]),
					.axis_rx_tdata(axis_out_tdata[row][col]),
					.axis_rx_tid(axis_out_tid[row][col]),
					.axis_rx_tdest(axis_out_tdest[row][col]),
					.axis_rx_tready(axis_out_tready[row][col]),
					.axis_tx_tvalid(axis_in_tvalid[row][col]),
					.axis_tx_tdata(axis_in_tdata[row][col]),
					.axis_tx_tid(axis_in_tid[row][col]),
					.axis_tx_tdest(axis_in_tdest[row][col]),
					.axis_tx_tready(axis_in_tready[row][col]),
					.axis_tx_tlast(axis_in_tlast[row][col])
				);
			end
		end
	end
	endgenerate
	
	localparam collector_row = node_r(COLLECTOR_NODE_ID);
	localparam collector_col = node_c(COLLECTOR_NODE_ID);

	collector #(
		  .DATAW(ACTUAL_DATAW),         // Bitwidth of axi-s tdata
		  .IDW(TID_WIDTH),            // Bitwidth of axi-s tid
	     .DESTW(TDEST_WIDTH)		   // Bitwidth of axi-s tdest
    ) collector_inst (
        .clk,
        .rst(~rst_n),
	     .data_fifo_ren(collector_fifo_ren),
		  .axis_rx_tvalid(axis_out_tvalid[collector_row][collector_col]),
	     .axis_rx_tdata(axis_out_tdata[collector_row][collector_col][ACTUAL_DATAW-1:0]),
	     .axis_rx_tid(axis_out_tid[collector_row][collector_col]),
	     .axis_rx_tdest(axis_out_tdest[collector_row][collector_col]),
	     .axis_rx_tready(axis_out_tready[collector_row][collector_col]),
	     .data_fifo_rdata(collector_fifo_rdata),
        .data_fifo_rdy(collector_fifo_rdy)
    );

	genvar dispatcher_id;
	generate 
		for (dispatcher_id = 0; dispatcher_id < NUM_MVMS_FIRST_LAYER; dispatcher_id++) begin: generate_dispatchers
			localparam row = node_r(DISPATCHER_NODE_IDS[dispatcher_id]);
			localparam col = node_c(DISPATCHER_NODE_IDS[dispatcher_id]);

			dispatcher #(
				.DATAW(ACTUAL_DATAW),         // Bitwidth of axi-s tdata
				.IDW(TID_WIDTH),            // Bitwidth of axi-s tid
				.DESTW(TDEST_WIDTH),		   // Bitwidth of axi-s tdest
				.DESTNODE(MVM_NODE_IDS[0][dispatcher_id])
			) dispatcher_inst (
				.clk,
				.rst(~rst_n),
				.data_fifo_wen(dispatcher_fifo_wen[dispatcher_id]),
				.data_last(dispatcher_last[dispatcher_id]),
				.axis_tx_tvalid(axis_in_tvalid[row][col]),
				.axis_tx_tdata(axis_in_tdata[row][col]),
				.axis_tx_tid(axis_in_tid[row][col]),
				.axis_tx_tdest(axis_in_tdest[row][col]),
				.axis_tx_tready(axis_in_tready[row][col]),
				.axis_tx_tlast(axis_in_tlast[row][col]),
				.data_fifo_wdata(dispatcher_fifo_wdata[dispatcher_id]),
				.data_fifo_rdy(dispatcher_fifo_rdy[dispatcher_id])
			);
		end
	endgenerate

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

	function int node_r(int node);
		return node / NUM_COLS;
	endfunction

	function int node_c(int node);
		return node % NUM_COLS;
	endfunction

	task parse_inputs;
		input string file;
		output [ACTUAL_DATAW-1:0] inputs [];

		integer data_file, scan_file;
		logic [ACTUAL_DATAW-1:0] data;
		begin
			inputs.delete();
			data_file = $fopen(file, "r");
			while(!$feof(data_file)) begin
				for (int i = 0; i < LANES; i++) begin
					scan_file = $fscanf(data_file, "%d ", data[i*IPRECISION +: IPRECISION]);
				end
				scan_file = $fscanf(data_file, "\n");
				
				inputs = new [inputs.size() + 1](inputs);
				inputs[inputs.size() - 1] = data;
			end
		end
	endtask

	task parse_send_instructions;
		input string file;
		input integer node;

		integer data_file, scan_file;
		logic [31:0] instruction;
		begin
			data_file = $fopen(file, "r");
			while(!$feof(data_file)) begin
				scan_file = $fscanf(data_file, "%b %d %d %d %b %b %b %b \n", instruction[31], instruction[30:22], instruction[21:13], instruction[12:4], instruction[3], instruction[2], instruction[1], instruction[0]);
				send_instruction(instruction, node, $feof(data_file) > 0);
			end
		end
	endtask

	task parse_send_weights;
		input string file;
		input integer dpe;
		input integer node;

		integer data_file, scan_file;
		integer addr;
		logic [ACTUAL_DATAW-1:0] data;
		begin
			data_file = $fopen(file, "r");
			addr = 0;
			while(!$feof(data_file)) begin
				for (int i = LANES - 1; i >=0; i--) begin
					scan_file = $fscanf(data_file, "%d ", data[i*IPRECISION +: IPRECISION]);
				end
				scan_file = $fscanf(data_file, "\n");
				
				send_weight(data, dpe, addr++, node, $feof(data_file) > 0);
			end
		end
	endtask

	task send_input;
		input [ACTUAL_DATAW-1:0] data;
		input integer dispatcher;
		input last;

		begin
			while (~dispatcher_fifo_rdy[dispatcher]) begin
				@(negedge clk);
			end
			dispatcher_fifo_wdata[dispatcher] = data;
			dispatcher_fifo_wen[dispatcher] = 1'b1;
			dispatcher_last[dispatcher] = last;
			@(negedge clk);
			dispatcher_fifo_wen[dispatcher] = 1'b0;
			dispatcher_last[dispatcher] = 1'b0;
		end
	endtask
	 
	 task send_instruction;
		input [31:0] instruction;
		input integer node;
		input last;

		static int row = node_r(INST_LOADER_NODE_ID);
		static int col = node_c(INST_LOADER_NODE_ID);

		begin
			while (~axis_in_tready[row][col]) begin
				@(negedge clk);
			end
			axis_in_tdata[row][col][31:0] = instruction;
			axis_in_tdata[row][col][DATA_WIDTH-1:ACTUAL_DATAW] = 1'b0 << 9;
			axis_in_tdest[row][col] = node;
			axis_in_tvalid[row][col] = 1'b1;
			axis_in_tlast[row][col] = last;
			@(negedge clk);
			axis_in_tdata[row][col] = 0;
			axis_in_tvalid[row][col] = 1'b0;
			axis_in_tlast[row][col] = 1'b0;
		end
	 endtask
	 
	 task send_weight;
		input [ACTUAL_DATAW-1:0] data;
		input integer dpe;
		input [8:0] rf_addr;
		input integer node;
		input bit last;

		static int row = node_r(WEIGHT_LOADER_NODE_ID);
		static int col = node_c(WEIGHT_LOADER_NODE_ID);

		begin
			bit [63:0] rf_en;
			rf_en = 1'b1 << dpe;
			while (~axis_in_tready[row][col]) begin
				@(negedge clk);
			end
			axis_in_tdata[row][col][ACTUAL_DATAW-1:0] = data;
			axis_in_tdata[row][col][DATA_WIDTH-1:ACTUAL_DATAW] = (rf_en << 11) | (2'h3 << 9) | rf_addr;
			axis_in_tdest[row][col] = node;
			axis_in_tvalid[row][col] = 1'b1;
			axis_in_tlast[row][col] = last;
			@(negedge clk);
			axis_in_tdata[row][col] = 0;
			axis_in_tvalid[row][col] = 1'b0;
			axis_in_tlast[row][col] = 1'b0;
		end
	 endtask

endmodule: axis_mesh_mlp_tb