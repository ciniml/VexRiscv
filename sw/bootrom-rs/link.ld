OUTPUT_ARCH( "riscv" )
ENTRY(_start)

MEMORY
{
    imem(rx)  : ORIGIN = 0x80000000, LENGTH = 32K
    dmem(rwx) : ORIGIN = 0x80000000 + 32K, LENGTH = 32K
}

SECTIONS
{
  .isr_vector : {
      . = ALIGN(4);
      KEEP(*(.isr_vector))
      . = ALIGN(4);
  } >imem
  .text : { 
      . = ALIGN(4);
      *(.text .text.*) 
      . = ALIGN(4);
  } >imem
  .rodata : { 
      . = ALIGN(4);
      *(.rodata .rodata.*) 
      . = ALIGN(4);
  } >imem
  .data : {
      . = ALIGN(4);
      *(.data .data.*)
      . = ALIGN(4);
  } >dmem AT>imem
  .bss : { 
      *(.bss) 
      . = ALIGN(4);
  } >dmem
  PROVIDE(stack_bottom = .);
  PROVIDE(_end = .);
  PROVIDE(end = .);
  PROVIDE(ramend = ORIGIN(dmem) + LENGTH(dmem));

  .eh_frame (INFO) : { KEEP(*(.eh_frame)) }
  .eh_frame_hdr (INFO) : { *(.eh_frame_hdr) }
}
