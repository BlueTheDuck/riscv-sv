#include "bsp.h"

#define loop for (;;)

volatile uint32_t *EXIT = (uint32_t *)0xF0000000;

void exit(int32_t status) {
  *EXIT = status;
  loop;
}
