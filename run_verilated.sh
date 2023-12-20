#!/bin/bash
set -e
verilator --sc --pins-bv 2 -Wno-fatal --exe -Wall -CFLAGS -std=c++17 main.cpp testbench.cpp rtl/mvm.v -v rtl/components.v -v rtl/datapath.v -v rtl/reduce.v -v rtl/accum.v -v rtl/dpe.v
make -j -C obj_dir -f Vmvm.mk Vmvm
obj_dir/Vmvm