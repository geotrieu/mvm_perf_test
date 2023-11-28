#pragma once


#include <chrono>
#include <systemc.h>
#include "global_defines.hpp"

#define NUM_DPES 2
#define NUM_REPEATS 100

struct axis_master {
    sc_out<bool> tvalid;
    sc_in<bool> tready;
    sc_out<sc_bv<AXIS_MAX_DATAW>> tdata;
    sc_out<sc_bv<AXIS_STRBW>> tstrb;
    sc_out<sc_bv<AXIS_KEEPW>> tkeep;
    sc_out<bool> tlast;
    sc_out<sc_bv<AXIS_IDW>> tid;
    sc_out<sc_bv<AXIS_DESTW>> tdest;
    sc_out<sc_bv<AXIS_USERW>> tuser;
};

struct axis_slave {
    sc_in<bool> tvalid;
    sc_out<bool> tready;
    sc_in<sc_bv<AXIS_MAX_DATAW>> tdata;
    sc_in<sc_bv<AXIS_STRBW>> tstrb;
    sc_in<sc_bv<AXIS_KEEPW>> tkeep;
    sc_in<bool> tlast;
    sc_in<sc_bv<AXIS_IDW>> tid;
    sc_in<sc_bv<AXIS_DESTW>> tdest;
    sc_in<sc_bv<AXIS_USERW>> tuser;
};

class TestBench : public sc_core::sc_module {
private:
    sc_time start_sim_time, end_sim_time;
    std::chrono::steady_clock::time_point start_time, end_time;

public:
    sc_in<bool> clk;
    sc_out<bool> rst;
    axis_master axis_rx;
    axis_slave axis_tx;

    TestBench(const sc_module_name& name);

    void Dispatch();
    void Collect();
    void SendInstruction(sc_bv<32> instruction);
    void SendWeights(int dpe, sc_bv<DATAW> row, sc_bv<9> rf_addr);
    void SendInputVector(sc_bv<DATAW> data);

    SC_HAS_PROCESS(TestBench);
};