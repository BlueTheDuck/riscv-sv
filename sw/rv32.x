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

  .data : { 
    . = ALIGN(4);
    _bdata_start = .;
    *(.rodata .rodata.*)
    *(.data .data.*)
    . = ALIGN(4);
    *(.got .got.*)
    _bdata_end = .;
    . = ALIGN(8);
    __global_pointer$ = .;
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
