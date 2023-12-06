`timescale 1ns / 1ps

`include "config.vh"

module axis_mesh_add_tb();
    localparam NUM_ROWS = 4;
    localparam NUM_COLS = 4;
    localparam DATA_WIDTH = 64;
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
	 
	 logic [DATA_WIDTH - 1 : 0] response;
	 logic response_valid;
	 
	 logic [DATA_WIDTH - 1 : 0] client_tdata;
	 logic client_tlast;
	 logic client_valid;
	 logic client_ready;
	 
	 int i;

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
		client_tlast = 1'b0;
		client_valid = 1'b0;
		client_tdata = 0;
		i = 1;
		@(negedge clk);
		//@(negedge clk);
		//@(negedge clk);
		//@(negedge clk);
		//@(negedge clk);
		//@(negedge clk);
		//@(negedge clk);
		rst_n = 1'b1;
		$stop;
		@(negedge clk);
		//@(negedge clk);
		//@(negedge clk);
		//@(negedge clk);
		//@(negedge clk);
		// start
		client_valid = 1'b1;
		while (i <= 20) begin
			client_tdata <= i;
			if (i == 20) begin
				client_tlast = 1'b1;
			end
			
			@(negedge clk);
			
			if (client_valid && client_ready) begin
				i = i + 1;
			end
		end
		client_valid = 1'b0;
		@(negedge clk);
		//@(negedge clk);
		//@(negedge clk);
		//@(negedge clk);
		//@(negedge clk);
		//@(negedge clk);
		
		//@(negedge clk);
		//@(negedge clk);
		//rst_n = 1'b0;
		//@(negedge clk);
		//@(negedge clk);
    end

	initial begin
		// check
		forever begin
			@(negedge clk);
			if (response_valid) begin
				$display("The sum received is: %d", response);
				if (response == 210) begin
					$display("PASS");
				end else begin
					$display("FAIL");
				end
				$finish;
			end
		end
		@(negedge clk);
	end

	 adder adder_inst(
		.clk,
		.rst_n,
		.axis_adder_tvalid(axis_out_tvalid[0][0]),
		.axis_adder_tlast(axis_out_tlast[0][0]),
		.axis_adder_tdata(axis_out_tdata[0][0]),
		.axis_adder_tready(axis_out_tready[0][0]),
		.response_valid,
		.response
	 );
	 
	 client client_inst(
		.clk,
		.rst_n,
		.client_tdata,
		.client_tlast,
		.client_valid,
		.axis_client_tready(axis_in_tready[0][3]),
		.client_ready,
		.axis_client_tvalid(axis_in_tvalid[0][3]),
		.axis_client_tlast(axis_in_tlast[0][3]),
		.axis_client_tdest(axis_in_tdest[0][3]),
		.axis_client_tid(axis_in_tid[0][3]),
		.axis_client_tdata(axis_in_tdata[0][3])
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

endmodule: axis_mesh_add_tb