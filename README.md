# MVM/MLP Performance Testing

This repo contains a couple of tests that can be ran
1) MVM Kernel, Verilated in SystemC (run_verilated.sh)
2) MVM Kernel, Simulated in ModelSim (run_vsim.sh)
3) MLP through a NoC simulation, Simulation in ModelSim (run_noc.sh)

Although not in the repo, a performance test of the MLP through a NoC simulation in RAD-Sim can be found in the
mlp_int8 example design in the RAD-Sim repo.

## MVM Kernel, Verilated in SystemC
The testbench is in `testbench.cpp`.
There are 2 main functions, Dispatch and Collect.
They function similarly to the RAD-Sim dispatch and collect modules in the `mlp_int8` design.

### Dispatch
In the dispatch function, there are 3 sections.
1) Instructions
    1) Each instruction is written in binary, following the format outlined here: https://rad-flow.readthedocs.io/en/docs-dev/examples/rad-sim-mlp-int8-design.html#instruction-format
2) Matrix Weights
3) Input Vectors

### Collect
The collect function checks three things:
1) The data returned is correct
2) The node the output vector should be sent to
3) If this output vector is a reduction vector or an input vector

### Parameters
There are two modifiable parameters in `testbench.hpp`.
1) NUM_DPES: The number of DPES to simulate results for
2) NUM_REPEATS: The number of times the input vectors should be sent in a loop

## MVM Kernel, Simulated in ModelSim
The testbench is located in `rtl/mvm_tb.v`.
The parameters and structure is similar to the Verilated System C testbench as outlined above.

The one difference is this testbench supports reduction vectors should you wish.
There is a commented block that sends the reduction vectors.

## MLP Simulation on ModelSim NoC
The NoC design is provided by CMU, and can be found here: https://github.com/ShashankOV/noc.

The files for this simulation is located in the `noc` directory.
The MLP RTL files itself can be found in the `noc/mlp` directory.

### Compiler
The compiler for the instruction set, weight vectors, and sample input vectors can be found in the `noc/compiler` folder.
The format is the same as the RAD-Sim `mlp_int8` example design. The testbench automatically loads most of these files in,
with notable exceptions being `layer_mvm_config`, and `mlp.place`.
This means manual configuration of the MVM layers parameters (such as number of layers, number of MVMs per layers, etc.), and the placement of each module onto the NoC is required in the testbench.

### Testbench Parameters
The testbench used for MLP simulation is `noc/testbench/axis_mesh_mlp_tb.sv`, and contains several parameters that are required to be configured.
1) The Compiler MIF Set (default: production)
    1) To run the entire MLP simulation, the production compiler MIF is used. Make sure that is the block that is uncommented
    2) To run a test limited example with only 2 layers and 3 MVMs, uncomment the Test Compiler MIF Set and recomment the production set
2) DPES (default: 64)
    1) Ensure the number of DPES match the instruction set compiled
3) NUM_LAYERS (default: 4)
    1) The number of layers in the MLP
4) NUM_MVMS (default: 3,3,2,2)
    1) The number of MVMs on each layer, comma-separated
5) MAX_MVMS (default: 3)
    1) Take the Max of the array NUM_MVMS
6) DISPATCHER_NODE_IDS
    1) Comma-separated values of which router node each dispatcher is connected to
    2) These values can be obtained from the `mlp.place` file, with the heading `input_dispatcherX`
    3) Must be changed every time the compiler is ran to generate another test set
7) MVM_NODE_IDS
    1) 2D CSV array of which router node each MVM in each layer is connected to
    2) ModelSim Full Edition does not require all layers to have the same amount of nodes
    3) ModelSim Starter Edition errors out if not all layers have the same amount of nodes (i.e. # of MVMs on all layers is not the same). We can simply substitute it with an arbitrary value (like 99)
    4) These values can be obtained from the `mlp.place` file, with the heading `layerX_mvmY`
    5) Must be changed every time the compiler is ran to generate another test set
8) WEIGHT_LOADER_NODE_ID
    1) Which router node the weight loader module is connected to
    2) This value can be obtained from the `mlp.place` file, with the heading `weight_loader`
    3) Must be changed every time the compiler is ran to generate another test set
9) INST_LOADER_NODE_ID
    1) Which router node the instruction loader module is connected to
    2) This value can be obtained from the `mlp.place` file, with the heading `inst_loader`
    3) Must be changed every time the compiler is ran to generate another test set
10) COLLECTOR_NODE_ID
    1) Which router node the collector module is connected to
    2) This value can be obtained from the `mlp.place` file, with the heading `output_collector`
    3) Must be changed every time the compiler is ran to generate another test set

In addition to the testbench file, the file `noc/testbench/config.vh` should be configured to the correct project directory, as this is necessary to read the inputs from the compiler.

### Testbench Technical Specifications
Due to the limitations of the NoC router, some fields of the AXI-S protocol are unavailable, such as the `tuser` field.
Since the MLP design directly relies on this field to convey important information, a work around has been implemented to append the `tuser` field in front
of the `tdata` field.

This version also changes the RAD-Sim design slightly to support `tlast`, a field this NoC simulator depends on to switch the crossbar.

This version takes advantage of memory initialization to directly load the weights into the memory block.
A python script, located at `noc/mif_to_hex.py` was developed to translate the weights from RAD-Sim format (.mif), to the required .hex format.

If desired, weights can also be loaded through the AXI-S protocol. There is a commented block inside the testbench that loads weights through AXI-S.
The parameter passed to the MVM module, `MEM_INIT_FILE_PREFIX` should also be removed if loading through AXI-S.

### Steps to run the MLP NoC simulation:
1) Run the Compiler
    1) Go to the `noc/compiler` directory, and run the python script `gen_testcase.py` with the desired layers and sizes.
    2) The number of input vectors can be changed inside the script itself, in the variable `num_test_inputs`
2) Translate the Weights from RAD-Sim format to hex
    1) Run the python script `noc/mif_to_hex.py` with the location of the weight MIFs.
    2) e.g. `$ python mif_to_hex.py compiler/weight_mifs`
3) Configure the Testbench
    1) Using the `layer_mvm_config` and `mlp.place` files generated from the compiler, update the testbench parameters (as described above) to match
4) Running the simulation
    1) In `run_noc.sh`, change the `ALTERA_MF_VER_LIBRARY_DIR` variable to the directory holding the `altera_mf_ver` library files. If running starter edition, simply change it to "altera_mf_ver". You may need to compile these files using Quartus if using the full version of ModelSim.
    2) Run `run_noc.sh`
    3) The elapsed time shown is the time it takes from the input vectors starting to be loaded in, to when all the results are sent back to the driver.