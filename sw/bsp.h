#ifndef __BSP_H__
#define __BSP_H__

void _start();

#include "stdint.h"

void dout(uint32_t);

extern volatile uint32_t *DATA_OUT;

#endif
