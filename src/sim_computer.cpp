#include "VComputer.h"
#include "verilated.h"

int main(int argc, char **argv) {
  const std::unique_ptr<VerilatedContext> contextp =
      std::make_unique<VerilatedContext>();

  Verilated::mkdir("logs");

  contextp->traceEverOn(true);
  contextp->commandArgs(argc, argv);

  const std::unique_ptr<VComputer> top{new VComputer{contextp.get()}};

  while (!contextp->gotFinish()) {
    top->eval();
    contextp->timeInc(1);
  }
  top->final();
  contextp->statsPrintSummary();

  return 0;
}
