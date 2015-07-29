SECTIONS
{
  . = 0x00200000;
  _start = .;
  .text : {
      *(.text)
  } 
  .data : {
       *(.data)
  } 
  /DISCARD/ : {
       *(*)
  }
}
