#include <systemc.h>
#include <verilated.h>
#include <Vmvm.h>
#include "testbench.hpp"
#include "global_defines.hpp"

struct axis_interface {
    sc_signal<bool> tvalid;
    sc_signal<bool> tready;
    sc_signal<sc_bv<AXIS_MAX_DATAW>> tdata;
    sc_signal<sc_bv<AXIS_STRBW>> tstrb;
    sc_signal<sc_bv<AXIS_KEEPW>> tkeep;
    sc_signal<bool> tlast;
    sc_signal<sc_bv<AXIS_IDW>> tid;
    sc_signal<sc_bv<AXIS_DESTW>> tdest;
    sc_signal<sc_bv<AXIS_USERW>> tuser;
};

int sc_main(int argc, char* argv[]) { // entry point
    sc_clock *clk = new sc_clock("clk", 5, SC_NS);
    sc_signal<bool> rst;
    axis_interface axis_rx;
    axis_interface axis_tx;

    //Testbench
    TestBench* tb = new TestBench("testbench");
    tb->clk(*clk);
    tb->rst(rst);
    tb->axis_rx.tvalid(axis_rx.tvalid);
    tb->axis_rx.tdata(axis_rx.tdata);
    tb->axis_rx.tstrb(axis_rx.tstrb);
    tb->axis_rx.tkeep(axis_rx.tkeep);
    tb->axis_rx.tid(axis_rx.tid);
    tb->axis_rx.tdest(axis_rx.tdest);
    tb->axis_rx.tuser(axis_rx.tuser);
    tb->axis_rx.tlast(axis_rx.tlast);
    tb->axis_rx.tready(axis_rx.tready);
    tb->axis_tx.tvalid(axis_tx.tvalid);
    tb->axis_tx.tdata(axis_tx.tdata);
    tb->axis_tx.tstrb(axis_tx.tstrb);
    tb->axis_tx.tkeep(axis_tx.tkeep);
    tb->axis_tx.tid(axis_tx.tid);
    tb->axis_tx.tdest(axis_tx.tdest);
    tb->axis_tx.tuser(axis_tx.tuser);
    tb->axis_tx.tlast(axis_tx.tlast);
    tb->axis_tx.tready(axis_tx.tready);

    //DUT
    Vmvm* vmvm = new Vmvm{"vmvm"};
    vmvm->clk(*clk);
    vmvm->rst(rst);
    vmvm->axis_rx_tvalid(axis_rx.tvalid);
    vmvm->axis_rx_tdata(axis_rx.tdata);
    vmvm->axis_rx_tstrb(axis_rx.tstrb);
    vmvm->axis_rx_tkeep(axis_rx.tkeep);
    vmvm->axis_rx_tid(axis_rx.tid);
    vmvm->axis_rx_tdest(axis_rx.tdest);
    vmvm->axis_rx_tuser(axis_rx.tuser);
    vmvm->axis_rx_tlast(axis_rx.tlast);
    vmvm->axis_rx_tready(axis_rx.tready);
    vmvm->axis_tx_tvalid(axis_tx.tvalid);
    vmvm->axis_tx_tdata(axis_tx.tdata);
    vmvm->axis_tx_tstrb(axis_tx.tstrb);
    vmvm->axis_tx_tkeep(axis_tx.tkeep);
    vmvm->axis_tx_tid(axis_tx.tid);
    vmvm->axis_tx_tdest(axis_tx.tdest);
    vmvm->axis_tx_tuser(axis_tx.tuser);
    vmvm->axis_tx_tlast(axis_tx.tlast);
    vmvm->axis_tx_tready(axis_tx.tready);
    
    Verilated::commandArgs(argc, argv);

    // Initialize SC model
    sc_start();

    // Cleanup
    delete clk;
    delete tb;
    vmvm->final();
    delete vmvm;
    return 0;
}
