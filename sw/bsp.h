#ifndef __BSP_H__
#define __BSP_H__

#include "stddef.h"
#include "stdint.h"

extern size_t strlen(const char *s) __attribute__((__pure__)) __attribute__((__nonnull__(1)));

__attribute__((naked, noreturn)) void _start();
extern void main();

extern volatile uint32_t *DATA_OUT;

#endif
