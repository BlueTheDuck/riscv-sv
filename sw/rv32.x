ENTRY(_start)

MEMORY {
  ROM (RX) : ORIGIN = 0, LENGTH = 4K
  RAM (RW) : ORIGIN = 4K, LENGTH = 4K
}
SECTIONS {
  .text : {
     *(.text .text.*)
  } >ROM

  .data : { 
    . = ALIGN(4);
    _bdata_start = .;
    *(.got .got.*)
    *(.data .data.*)
    _bdata_end = .;
  } >ROM

  .bss (NOLOAD) : {
    . = ALIGN(4);
    _bss_start = .;
    *(.bss .bss.*)
    _bss_end = .;
  } >RAM
}
