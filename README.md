# RISCV-SV

## Overview

RISCV-SV
Welcome to RISCV-SV, a SystemVerilog implementation of a RISC-V CPU designed for educational purposes.

The main objective of this project is to showcase a real CPU written in SystemVerilog, following modern programming techniques and clean code principles while also providing a fully functional RISC-V core that can be run on real FPGAs.

This project is intended to be used by students who want to learn SystemVerilog, RISC-V or systems programming in general. The code is designed to be straightforward and easy to understand; with diagrams, guides and tools to aid in the usage and extension of the project.

Key features:
- **RISC-V ISA Support**: RV32I with some extensions planned
- **Simulation Tools**: Includes a simulation environment for testing and debugging.
- **Educational Focus**: Aimed at students and enthusiasts learning CPU architecture.

Make sure to check the [Wiki tab](https://github.com/BlueTheDuck/riscv-sv/wiki), as that is where every component of the system is detailed.

## Project Strucutre

- `src`: SystemVerilog code, including both Core and simulation environment
- `tb`: Individual test benches
- `tools`: GTKWave enum files, inline disassembler, etc.
- `sw`: GCC toolchain, the linker+memory script and BSP needed to run real code on the simulation environment
- `docs`: Info on the model itself

## Usage

By default the provided Makefile will:

1. [Verilate](https://veripool.org/guide/latest/verilating.html) the model, starting from [Computer](src/Computer.sv)
2. Compile `sw/bsp.c` and `sw/main.c` into `sw/main.bin`
3. Initialize main RAM with the contents of `sw/main.bin` and run the simulation

When the simulation finishes there will be two files inside the `logs/` folder:
- `computer.vcd`: The entire machine's wavetrace
- `ram.bin`: The binary dump of main RAM

The following tasks are available:
- `make clean`
- `make build`
- `make run` (as described above)
