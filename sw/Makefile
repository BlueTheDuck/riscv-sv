ifeq ($(DOCKER),1)
WRAPPER := docker run -it --user 1000:1000 --rm -v $(shell pwd):/opt/workdir rv32i:latest
else
WRAPPER :=
endif
TARGET := riscv32-unknown-elf

CC := $(WRAPPER) $(TARGET)-gcc
LD := $(WRAPPER) $(TARGET)-ld
OBJCOPY := $(WRAPPER) $(TARGET)-objcopy
OBJDUMP := $(WRAPPER) $(TARGET)-objdump

C_FLAGS := -ffunction-sections -fdata-sections -Xlinker "-Trv32.x" -nostartfiles -nostdlib -fpie -march=rv32id -mabi=ilp32d
LD_FLAGS := -Trv32.x

SRCS := $(wildcard *.c) $(wildcard *.s)
OBJS := $(patsubst %.c,%.o,$(wildcard *.c)) $(patsubst %.s,%.o,$(wildcard *.s))

bsp.o: C_FLAGS += -Oz

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
	-rm main *.o *.bin
.PHONY: clean
