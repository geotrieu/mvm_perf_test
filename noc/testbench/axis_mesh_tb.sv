`timescale 1ns / 1ps

module axis_mesh_tb();
    logic clk, clk_noc, rst_n;

    initial begin
        clk = 0;
        forever begin
            #5 clk = ~clk;
        end
    end

    initial begin
        clk_noc = 0;
        forever begin
            #5 clk_noc = ~clk_noc;
        end
    end

    logic axis_in_tvalid [5][2];
    logic axis_in_tready [5][2];
    logic [511:0] axis_in_tdata [5][2];
    logic axis_in_tlast [5][2];
    logic [3:0] axis_in_tdest [5][2];

    logic axis_out_tvalid [5][2];
    logic axis_out_tready [5][2];
    logic [511:0] axis_out_tdata [5][2];
    logic axis_out_tlast [5][2];
    logic [3:0] axis_out_tdest [5][2];

    initial begin
        axis_in_tvalid[0][0] = 1'b0;
        axis_in_tvalid[0][1] = 1'b0;
        axis_in_tvalid[1][0] = 1'b0;
        axis_in_tvalid[1][1] = 1'b0;
        axis_in_tvalid[2][0] = 1'b0;
        axis_in_tvalid[2][1] = 1'b0;
        axis_in_tvalid[3][0] = 1'b0;
        axis_in_tvalid[3][1] = 1'b0;
        axis_in_tvalid[4][0] = 1'b0;
        axis_in_tvalid[4][1] = 1'b0;

        axis_out_tready[0][0] = 1'b1;
        axis_out_tready[0][1] = 1'b1;
        axis_out_tready[1][0] = 1'b1;
        axis_out_tready[1][1] = 1'b1;
        axis_out_tready[2][0] = 1'b1;
        axis_out_tready[2][1] = 1'b1;
        axis_out_tready[3][0] = 1'b1;
        axis_out_tready[3][1] = 1'b1;
        axis_out_tready[4][0] = 1'b1;
        axis_out_tready[4][1] = 1'b1;

        rst_n = 1'b0;

        @(negedge clk);
        @(negedge clk);
        @(negedge clk);
        @(negedge clk);

        rst_n = 1'b1;

        @(negedge clk);
        @(negedge clk);
        @(negedge clk);
        @(negedge clk);
        @(negedge clk);
        @(negedge clk);
        @(negedge clk);
        @(negedge clk);
        @(negedge clk);
        @(negedge clk);
        @(negedge clk);
        @(negedge clk);
        @(negedge clk);
        @(negedge clk);
        @(negedge clk);
        @(negedge clk);
        @(negedge clk);
        @(negedge clk);
        @(negedge clk);
        @(negedge clk);
        @(negedge clk);

        // axis_in_tdest[0][0] = 4'h1;
        // axis_in_tlast[0][0] = 1'b1;
        // axis_in_tdata[0][0] = 512'h1;
        // axis_in_tvalid[0][0] = 1'b1;
        // @(negedge clk);
        // axis_in_tdest[0][0] = 4'h2;
        // @(negedge clk);
        // axis_in_tdest[0][0] = 4'h3;
        // @(negedge clk);
        // axis_in_tvalid[0][0] = 1'b0;
        // axis_in_tdest[0][1] = 4'h0;
        // axis_in_tlast[0][1] = 1'b1;
        // axis_in_tdata[0][1] = 512'h1;
        // axis_in_tvalid[0][1] = 1'b1;
        // @(negedge clk);
        // axis_in_tdest[0][1] = 4'h2;
        // @(negedge clk);
        // axis_in_tdest[0][1] = 4'h3;
        // @(negedge clk);
        // axis_in_tvalid[0][1] = 1'b0;
        @(negedge clk);
        axis_in_tvalid[1][0] = 1'b1;
        axis_in_tdest[1][0] = 4'h1;
        axis_in_tlast[1][0] = 1'b1;
        axis_in_tdata[1][0] = 512'h1;

        @(negedge clk);
        @(negedge clk);
        @(negedge clk);
        @(negedge clk);
        @(negedge clk);
        @(negedge clk);
        @(negedge clk);
        @(negedge clk);
        @(negedge clk);
        @(negedge clk);
        @(negedge clk);
        @(negedge clk);
        @(negedge clk);
        @(negedge clk);
        @(negedge clk);
        @(negedge clk);
        @(negedge clk);
        @(negedge clk);
        @(negedge clk);
        @(negedge clk);
        @(negedge clk);
        @(negedge clk);
        @(negedge clk);
        @(negedge clk);
        @(negedge clk);
        @(negedge clk);
        @(negedge clk);
        @(negedge clk);
        @(negedge clk);
        @(negedge clk);
        @(negedge clk);
        @(negedge clk);
        @(negedge clk);
        @(negedge clk);
        @(negedge clk);
        @(negedge clk);
        @(negedge clk);
        @(negedge clk);
        @(negedge clk);
        @(negedge clk);
        @(negedge clk);
        @(negedge clk);
        @(negedge clk);
        @(negedge clk);
        @(negedge clk);
        @(negedge clk);
        @(negedge clk);
        @(negedge clk);
        @(negedge clk);
        @(negedge clk);
        @(negedge clk);
        @(negedge clk);
        @(negedge clk);
        @(negedge clk);
        $finish;
    end

        axis_mesh #(
        .NUM_ROWS                   (5),
        .NUM_COLS                   (2),
        .PIPELINE_LINKS             (1),

        .TDEST_WIDTH                (4),
        .TDATA_WIDTH                (512),
        .SERIALIZATION_FACTOR       (4),
        .CLKCROSS_FACTOR            (1),
        .SINGLE_CLOCK               (1),
        .SERDES_IN_BUFFER_DEPTH     (4),
        .SERDES_OUT_BUFFER_DEPTH    (4),
        .SERDES_EXTRA_SYNC_STAGES   (0),

        .FLIT_BUFFER_DEPTH          (4),
        .ROUTING_TABLE_PREFIX       ("routing_tables/mesh_5x2/"),
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
        // .axis_in_tid    ,
        .axis_in_tdest  ,

        .axis_out_tvalid,
        .axis_out_tready,
        .axis_out_tdata ,
        .axis_out_tlast ,
        // .axis_out_tid   ,
        .axis_out_tdest
    );

endmodule: axis_mesh_tb