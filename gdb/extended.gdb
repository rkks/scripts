#--------Process---------
#************Commands*************
define args
 show args
end

define istack
 info stack
end

define iframe
 info frame
 info args
 info locals
end

define ireg
 #info registers
 info all-registers
end

define ifunc
 info functions
end

define ivar
 info variables
end

define ilib
 info sharedlibrary
end

define isig
 info signals
end

define ithr
 info threads
end

define dis
 disassemble $arg0
end

define pm
 echo backtrace:\n
 backtrace full
 echo \n\nregisters:\n
 info registers
 echo \n\ncurrent instructions:\n
 x/16i $pc
 echo \n\nthreads backtrace:\n
 thread apply all backtrace
end

#*******Documentation*********
document args
Print program arguments
end

document istack
Print call stack
end

document iframe
Print stack frame
end

document ireg
Print CPU registers
end

document ifunc
Print functions in target
end

document ivar
Print variables (symbols) in target
end

document ilib
Print shared libraries linked to target
end

document isig
Print signal actions for target
end

document ithr
Print threads in target
end

document dis
Disassemble address
Usage: dis addr
end

document pm
 Displays the execution summary
end
#--------Process---------

#------Hex Dump-------
#************Commands*************
define ascii_char
 set $_c=*(unsigned char *)($arg0)
 if ( $_c < 0x20 || $_c > 0x7E )
  printf "."
 else
  printf "%c", $_c
 end
end

define hex_quad
 printf "%02X %02X %02X %02X  %02X %02X %02X %02X",                  \
		*(unsigned char*)($arg0), *(unsigned char*)($arg0 + 1),      \
		*(unsigned char*)($arg0 + 2), *(unsigned char*)($arg0 + 3),  \
		*(unsigned char*)($arg0 + 4), *(unsigned char*)($arg0 + 5),  \
		*(unsigned char*)($arg0 + 6), *(unsigned char*)($arg0 + 7)
end

define hexdump
 printf "%08X : ", $arg0
 hex_quad $arg0
 printf " - "
 hex_quad ($arg0+8)
 printf " "

 ascii_char ($arg0)
 ascii_char ($arg0+1)
 ascii_char ($arg0+2)
 ascii_char ($arg0+3)
 ascii_char ($arg0+4)
 ascii_char ($arg0+5)
 ascii_char ($arg0+6)
 ascii_char ($arg0+7)
 ascii_char ($arg0+8)
 ascii_char ($arg0+9)
 ascii_char ($arg0+0xA)
 ascii_char ($arg0+0xB)
 ascii_char ($arg0+0xC)
 ascii_char ($arg0+0xD)
 ascii_char ($arg0+0xE)
 ascii_char ($arg0+0xF)

 printf "\n"
end

define dump_to_file
 dump ihex memory $arg0 $arg1 $arg2
end

#*******Documentation*********
document hexdump
Display a 16-byte hex/ASCII dump of arg0
end

document hex_quad
Print eight hexadecimal bytes starting at arg0
end

document ascii_char
Print the ASCII value of arg0 or '.' if value is unprintable
end

document dump_to_file
Write a range of memory to a file in Intel ihex (hexdump) format.
Usage:	dump_to_file filename start_addr end_addr
end
#------Hex Dump-------

#------Read/Writes-------
#************Commands*************
define wbyte
 set * (unsigned char *) $arg0 = $arg1
end

define wword
 set * (unsigned short *) $arg0 = $arg1
end

define wdword
 set * (unsigned long *) $arg0 = $arg1
end

#**********Documentation**********
document wbyte
Write byte at address arg0 to a given value/instruction
Usage: wbyte addr value/instr
end

document wword
Write word at address arg0 to a given value/instruction
Usage: wword addr value/instr
end

document wdword
Write double word at address arg0 to a given value/instruction
Usage: wdword addr value/instr
end
#------Read/Writes-------

