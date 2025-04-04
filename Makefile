.DEFAULT: run

TOP := Computer
VERILATOR_ARGS :=	+1800-2017ext+sv -sv --trace --relative-includes --timing \
				+incdir+./src -y src \
 				--cc --exe --build \
        --x-assign unique --x-initial unique \
				--assert -Wall -Wno-fatal -Wpedantic -Wwarn-lint -Wwarn-style -Wno-VARHIDDEN \
				-j 0
SRCS := $(wildcard src/*.sv)
MODULES := src/Types.sv
SIM_MAIN := src/sim_computer.cpp
INIT_FILE := sw/main.bin

# Note: Verilator automatically handles the dependencies and rebuilds the model if needed
.PHONY: build run

build:
	verilator $(VERILATOR_ARGS) $(SIM_MAIN) --top $(TOP) $(MODULES) src/$(TOP).sv

run: build $(INIT_FILE)
	./obj_dir/V$(TOP) +INIT_FILE=$(INIT_FILE)

$(INIT_FILE):
	$(MAKE) DOCKER=1 -C sw $(notdir $@)

clean:
	-make -C sw clean
	-rm obj_dir/*.o obj_dir/V$(TOP) obj_dir/sim_computer
	-rm ram.bin rom.bin