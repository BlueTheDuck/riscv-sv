#include "bsp.h"

#define loop for (;;)

volatile uint32_t *DATA_OUT = (uint32_t *)0xF0000000;
extern uint32_t _bss_start, _bss_end;

void _start() {
  asm volatile("lui sp, %hi(__stack_top$)\n"
               "addi sp, sp, %lo(__stack_top$)");
  asm volatile("lui gp, %hi(__global_pointer$)\n"
               "addi gp, gp, %lo(__global_pointer$)");
  for (uint32_t *bss = &_bss_start; bss != &_bss_end; bss++) {
    *bss = 0;
  }
  main();
  *DATA_OUT = 0x0;
  loop {}
}
