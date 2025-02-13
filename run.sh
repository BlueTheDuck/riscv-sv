#!/bin/env bash
ARGS="+1800-2017ext+sv -sv --trace --relative-includes --timing --top Computer \
				+incdir+./src -y src \
 				--build --binary --assert \
        --x-assign unique --x-initial unique \
				-Wall -Wno-fatal -Wpedantic -Wwarn-lint -Wwarn-style  \
        -Wno-VARHIDDEN \
        -DDUMP_FINAL_STATE -DPRETTY_WAVETRACE \
				-j 0"
      
rm trace.vcd
rm ram.hexdump

clear;
verilator $ARGS \
  src/Types.sv src/Computer.sv \
  && obj_dir/VComputer
