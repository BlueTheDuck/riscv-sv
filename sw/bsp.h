#ifndef __BSP_H__
#define __BSP_H__

#include "stdint.h"

__attribute__((naked, noreturn)) void _start();
extern void main();

extern volatile uint32_t *DATA_OUT;

#endif
