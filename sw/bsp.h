#ifndef __BSP_H__
#define __BSP_H__

#include "stdint.h"

__attribute__((naked, noreturn)) void _start();
extern void main() __attribute__((noreturn));
// maybe main shouldn't be noreturn?

extern volatile uint32_t *DATA_OUT;

#endif
