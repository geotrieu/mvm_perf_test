#!/bin/bash
set -e

ALTERA_MF_VER_LIBRARY_DIR=/home/trieugeo/quartus-sim-libs/verilog_libs/altera_mf_ver

vsim -c -do "vlog noc/*.sv noc/testbench/*.sv noc/mlp/*.v noc/mlp/*.sv;  vsim -L $ALTERA_MF_VER_LIBRARY_DIR work.axis_mesh_mlp_tb; restart; run -all; time \"run -all\"; exit"