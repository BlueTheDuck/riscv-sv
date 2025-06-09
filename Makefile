.DEFAULT: run

TOP := Computer
VERILATOR_ARGS :=	+1800-2017ext+sv -sv --trace --relative-includes --timing \
				+incdir+./src -y src \
 				--cc --exe --binary \
        --x-assign unique --x-initial unique \
				--assert -Wall -Wno-fatal -Wpedantic -Wwarn-lint -Wwarn-style -Wno-VARHIDDEN \
				-j 0
SRCS := $(wildcard src/*.sv)
MODULES := src/Types.sv
INIT_FILE := sw/main.bin
SV2V := tools/sv2v

# Note: Verilator automatically handles the dependencies and rebuilds the model if needed
.PHONY: build run

build:
	verilator $(VERILATOR_ARGS) --top $(TOP) $(MODULES) src/$(TOP).sv

run: build $(INIT_FILE)
	./obj_dir/V$(TOP) +__DUMP_STATE__ +INIT_FILE=$(INIT_FILE)

$(INIT_FILE):
	$(MAKE) -C sw $(notdir $@)

clean:
	-make -C sw clean
	-rm obj_dir/*.o obj_dir/V$(TOP) obj_dir/sim_computer
	-rm logs/*.bin logs/*.vcd
	-rm dist.v

dist.v: src/CpuWrapper.sv $(SRCS)
	$(SV2V) -y src -I src --write=$@ --top $(basename $(<F)) $^

cputb:
	mkdir -p obj_dir/tb_cpu
	verilator --Mdir obj_dir/tb_cpu $(VERILATOR_ARGS) $(SIM_MAIN) --top CpuTb $(MODULES) tb/CpuTb.sv
	./obj_dir/tb_cpu/VCpuTb
.PHONY: cputb
