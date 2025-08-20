.extern __stack_top$
.extern __global_pointer$
.extern main
.extern exit

.section .text._start
.global _start

_start:

.option push
.option norelax
  la sp, __stack_top$
  la gp, __global_pointer$
.option pop

.bss_init:
  la a5, _bss_start
  la a4, _bss_end
1:
  beq  a5, a4, call_main
  sw   zero, 0(a5)
  addi a5, a5, 4
  bne  a5, a4, 1b
.call_main:
  # main(0, NULL);
  li   a0, 0
  li   a1, 0
  call main
  tail exit
halt:
  j halt
