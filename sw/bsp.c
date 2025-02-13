#include "bsp.h"
#define loop for(;;)

volatile uint32_t *DATA_OUT = (uint32_t *)0xF0000000;

extern void main();

extern uint32_t *_bss_start, *_bss_end;

static int random[4];

__attribute__((naked))
void _start() {
  for (uint32_t *i = _bss_start; i < _bss_end; i += 4) {
    *i = 0;
  }
  main();
  loop {}
}

void dout(uint32_t data) {
  asm volatile("li t0, 0xF0000000;"
               "sw %[d], 0(t0)"
               :
               : [d] "r"(data)
               : "t0", "memory");
}
