#include "stdint.h"

#define loop for (;;)

volatile uint32_t* DATA_OUT = (uint32_t*)0xF0000000;

__attribute__((naked))
void _start() {
    uint32_t a = 0, b = 1;
    loop {
        uint32_t c = a + b;
        a = b;
        b = c;
    }
}
