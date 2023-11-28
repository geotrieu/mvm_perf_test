#include "testbench.hpp"

TestBench::TestBench(const sc_module_name& name) {
    SC_CTHREAD(Dispatch, clk.pos());
    SC_CTHREAD(Collect, clk.pos());
}

void TestBench::Dispatch() {
    //reset
    rst.write(true);
    axis_rx.tvalid.write(false);
    axis_tx.tready.write(false);
    wait();
    rst.write(false);
    axis_tx.tready.write(true);

    /***********************INSTRUCTIONS*****************************************************/
	// Send Instruction 0 (Calculate DP of first chunk, first input vector)
	SendInstruction(0b0'000000000'000000000'000000000'0'0'0'0);
	wait();
	
	// Send Instruction 1 (Calculate DP of second chunk, first input vector)
	SendInstruction(0b0'000000000'000000001'000000001'0'0'0'0);
	wait();
	
	// Send Instruction 2 (Calculate DP of third chunk, first input vector)
	SendInstruction(0b0'000000000'000000010'000000010'0'0'0'0);
	wait();
	
	// Send Instruction 3 (Calculate DP of fourth chunk (last), first input vector)
	SendInstruction(0b0'000000000'000000011'000000011'1'0'0'0);
	wait();
	
	// Send Instruction 4 (Calculate DP of first chunk, second input vector (last), accumulate, reduce, and release IV to node 1)
	SendInstruction(0b1'000000001'000100000'000000000'0'1'1'0);
	wait();
	
	// Send Instruction 5 (Calculate DP of second chunk, second input vector (last), accumulate, reduce, and release IV to node 2)
	SendInstruction(0b1'000000010'000100001'000000001'0'1'1'0);
	wait();
	
	// Send Instruction 6 (Calculate DP of third chunk, second input vector (last), accumulate, reduce, and release IV to node 1)
	SendInstruction(0b1'000000001'000100010'000000010'0'1'1'0);
	wait();
	
	// Send Instruction 7 (Calculate DP of fourth chunk (last), second input vector (last), accumulate, reduce, and release IV to node 2)
	SendInstruction(0b1'000000010'000100011'000000011'1'1'1'0);
	wait();
	/****************************************************************************************/
    std::cout << "All Instructions sent!" << std::endl;

    /***********************MATRIX DATA******************************************************/
	// Send Matrix Data to RFi, chunk 0, first input vector
    for (int dpe = 0; dpe < NUM_DPES; dpe++) {
        sc_bv<DATAW> data = (1 << 16) | (1 << 8) | (1); // [1,1,1]
        SendWeights(dpe, data, 0x0);
        wait();
    }
	
	// Send Matrix Data to RFi, chunk 1, first input vector
	for (int dpe = 0; dpe < NUM_DPES; dpe++) {
        sc_bv<DATAW> data = (2 << 16) | (2 << 8) | (2); // [2,2,2]
        SendWeights(dpe, data, 0x1);
        wait();
    }
	
	// Send Matrix Data to RFi, chunk 2, first input vector
	for (int dpe = 0; dpe < NUM_DPES; dpe++) {
        sc_bv<DATAW> data = (3 << 16) | (3 << 8) | (3); // [3,3,3]
        SendWeights(dpe, data, 0x2);
        wait();
    }
	
	// Send Matrix Data to RFi, chunk 3, first input vector
	for (int dpe = 0; dpe < NUM_DPES; dpe++) {
        sc_bv<DATAW> data = (4 << 16) | (4 << 8) | (4); // [4,4,4]
        SendWeights(dpe, data, 0x3);
        wait();
    }
	
	// Send Matrix Data to RFi, chunk 0, second input vector
	for (int dpe = 0; dpe < NUM_DPES; dpe++) {
        sc_bv<DATAW> data = (4 << 16) | (4 << 8) | (4); // [4,4,4]
        SendWeights(dpe, data, 0x20);
        wait();
    }
	
	// Send Matrix Data to RFi, chunk 1, second input vector
	for (int dpe = 0; dpe < NUM_DPES; dpe++) {
        sc_bv<DATAW> data = (3 << 16) | (3 << 8) | (3); // [3,3,3]
        SendWeights(dpe, data, 0x21);
        wait();
    }
	
	// Send Matrix Data to RFi, chunk 2, second input vector
	for (int dpe = 0; dpe < NUM_DPES; dpe++) {
        sc_bv<DATAW> data = (2 << 16) | (2 << 8) | (2); // [2,2,2]
        SendWeights(dpe, data, 0x22);
        wait();
    }
	
	// Send Matrix Data to RFi, chunk 3, second input vector
	for (int dpe = 0; dpe < NUM_DPES; dpe++) {
        sc_bv<DATAW> data = (1 << 16) | (1 << 8) | (1); // [1,1,1]
        SendWeights(dpe, data, 0x23);
        wait();
    }
	/****************************************************************************************/
    std::cout << "All Weights sent!" << std::endl;

    // Start Measurements
    start_time = std::chrono::steady_clock::now(); // wall time
    start_sim_time = sc_time_stamp();

    /***********************INPUT VECTORS****************************************************/
    for (int i = 0; i < NUM_REPEATS; i++) {
        // Send Input Vector 0
        SendInputVector((1 << 16) | (1 << 8) | (1)); // [1,1,1]
        wait();
        
        // Send Input Vector 1
        SendInputVector((2 << 16) | (2 << 8) | (2)); // [2,2,2]
        wait();
    }
	/****************************************************************************************/
    std::cout << "All Input Vectors sent!" << std::endl;
    
    axis_rx.tvalid.write(false);
}

void TestBench::Collect() {
    bool passing = true;
	int count = 0;
    int repeats = 0;
    while (true) {
        if (axis_tx.tvalid.read()) {
            sc_bv<DATAW> tdata = axis_tx.tdata.read();
            sc_bv<AXIS_USERW> tuser = (axis_tx.tuser.read() >> 9) & 0x3; //bits 9 and 10 of tuser
            sc_bv<AXIS_DESTW> tdest = axis_tx.tdest.read();
            switch (count) {
                case 0:
                    if (tdata != 0x1B1B || tuser != 0x2 || tdest != 1) passing = 0;
                    break;
                case 1:
                    if (tdata != 0x1818 || tuser != 0x2 || tdest != 2) passing = 0;
                    break;
                case 2:
                    if (tdata != 0x1515 || tuser != 0x2 || tdest != 1) passing = 0;
                    break;
                case 3:
                    if (tdata != 0x1212 || tuser != 0x2 || tdest != 2) passing = 0;
                    break;
            }
            count++;
        }

        if (count == 4) {
            repeats++;
            count = 0;

            if (repeats == NUM_REPEATS) {
                if (passing) {
                    std::cout << "Simulation PASSED!" << std::endl;
                } else {
                    std::cout << "Simulation FAILED!" << std::endl;
                }

                end_time = std::chrono::steady_clock::now(); //wall time
                end_sim_time = sc_time_stamp(); //sim time

                std::cout << "Simulation Cycles = " << (end_sim_time - start_sim_time).to_default_time_units() / CLOCK_PERIOD_NS << std::endl;
                std::cout << "Simulation Time = " << std::chrono::duration_cast<std::chrono::microseconds> (end_time - start_time).count() << " us" << std::endl;

                sc_stop();
            }
        }

        wait();
    }
}

void TestBench::SendInputVector(sc_bv<DATAW> data) {
  axis_rx.tdest.write(0x0);
  axis_rx.tuser.write(0x2 << 9);
  axis_rx.tdata.write(data);
  axis_rx.tvalid.write(true);
}

void TestBench::SendInstruction(sc_bv<32> instruction) {
  axis_rx.tdest.write(0x0);
  axis_rx.tuser.write(0x0 << 9);
  axis_rx.tdata.write(instruction);
  axis_rx.tvalid.write(true);
}

void TestBench::SendWeights(int dpe, sc_bv<DATAW> data, sc_bv<9> rf_addr) {
  sc_bv<64> rf_en = 1 << dpe;
  axis_rx.tdest.write(0x0);
  axis_rx.tuser.write((rf_en << 11) | (0x3 << 9) | rf_addr);
  axis_rx.tdata.write(data);
  axis_rx.tvalid.write(true);
}