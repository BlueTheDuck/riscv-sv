ENTRY(_start)

MEMORY {
  ROM (RX) : ORIGIN = 0, LENGTH = 4K
  RAM (RW) : ORIGIN = 4K, LENGTH = 4K
}
SECTIONS {
  .text : {
     KEEP( *(.text._start) )
     *(.text .text.*)
  } >ROM

  .rodata : {
      . = ALIGN(4);
      *(.rdata)
      *(.rodata .rodata.*)
  } >ROM

  .data : { 
    . = ALIGN(4);
    *(.data .data.*)
    PROVIDE (__global_pointer$ = . + 0x800);
  } >ROM

  .bss (NOLOAD) : {
    . = ALIGN(4);
    _bss_start = .;
    *(.bss .bss.*)
    . = ALIGN(4);
    _bss_end = .;
  } >RAM
}

__stack_top$ = ORIGIN(RAM) + LENGTH(RAM);
