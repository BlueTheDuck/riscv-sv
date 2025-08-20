#ifndef __BSP_H__
#define __BSP_H__

#include "stddef.h"
#include "stdint.h"

__attribute__((noreturn))
void exit(int32_t status);
extern uint32_t main(uint32_t argc, char **argv);

extern volatile uint32_t *EXIT;

#endif
