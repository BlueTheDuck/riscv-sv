.extern __stack_top$
.extern __global_pointer$
.extern main
.extern exit

.section .text._start
.global _start

_start:

.option push
.option norelax
  lui sp, %hi(__stack_top$)
  addi sp, sp, %lo(__stack_top$)
  lui gp, %hi(__global_pointer$)
  addi gp, gp, %lo(__global_pointer$)
.option pop

.bss_init:
  lui  a5, %hi(_bss_start)
  addi a5, a5, %lo(_bss_start)
  lui  a4, %hi(_bss_end)
  addi a4, a4, %lo(_bss_end)
1:
  beq  a5, a4, 2f
  sw   zero, 0(a5)
  addi a5, a5, 4
  j    1b
2:

  jal main
  jal exit
halt:
  j halt
  

