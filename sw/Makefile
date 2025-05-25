ifndef TOOLCHAIN_PATH
TOOLCHAIN_PATH := /opt/riscv/bin/
$(warning "TOOLCHAIN_PATH is not set, using default: $(TOOLCHAIN_PATH)")
endif

export PATH := $(TOOLCHAIN_PATH):$(PATH)

TARGET := riscv32-unknown-elf

CC := $(TARGET)-gcc
LD := $(TARGET)-ld
OBJCOPY := $(TARGET)-objcopy
OBJDUMP := $(TARGET)-objdump

C_FLAGS := -ffunction-sections -fdata-sections -Xlinker "-Trv32.x" -nostartfiles -nostdlib -fpie -march=rv32id -mabi=ilp32d
LD_FLAGS := -Trv32.x

SRCS := $(wildcard *.c) $(wildcard *.s)
OBJS := $(patsubst %.c,%.o,$(wildcard *.c)) $(patsubst %.s,%.o,$(wildcard *.s))

bsp.o: C_FLAGS += -Oz -Wl,--no-relax
main.o: C_FLAGS += -O1

%.o: %.s
	$(CC) $(C_FLAGS) -x assembler -c -o $@ $<

%.o: %.c
	$(CC) $(C_FLAGS) -c -o $@ $<

main: $(OBJS)
	$(LD) $^ $(LD_FLAGS) -o $@

hexdump: main
	$(OBJDUMP) -d $<
	$(OBJDUMP) -t $<
.PHONY: hexdump

%.bin: %
	$(OBJCOPY) -Obinary $< $@

clean:
	-rm main *.o *.bin *.dmp *.dmp.txt
.PHONY: clean
