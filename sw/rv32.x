
MEMORY {
  ROM (rx) : ORIGIN = 0, LENGTH = 4K
  RAM (rw) : ORIGIN = 4K, LENGTH = 4K
}
SECTIONS {
  ENTRY(_start)
  .text : { *(.text) } >ROM
  .data : { *(.data) } >ROM
}

