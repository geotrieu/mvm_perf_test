#!/bin/bash
set -e
vsim -c -do "vlog rtl/*.v; vsim work.mvm_tb; restart; run -all; time \"run -all\"; exit"