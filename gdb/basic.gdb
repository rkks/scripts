#-----------Init Control----------
define binit
    tbreak _init
    run
end

document binit
    Run program; break on _init()
end

define bstart
    tbreak _start
    run
end

document bstart
    Run program; break on _start()
end

define bsstart
    tbreak __libc_start_main
    run
end

document bsstart
    Run program; break on __libc_start_main(). Useful for stripped executables.
end

define bmain
    tbreak main
    commands
        silent
        info all-reg
        info frame
        info stack
    end
    run
end

document bmain
    Run program; break on main()
end

define procinfo
    printf "**\n** Process Info: \n**\n"
    info proc
    printf "*\n* Libraries \n*\n"
    info sharedlib
    printf "*\n* Memory Map \n*\n"
    info target
    printf "*\n* Registers \n*\n"
    info registers
    printf "*\n* Current Instructions \n*\n"
    x/16i $pc
    printf "*\n* Threads (basic) \n*\n"
    info threads
    thread apply all bt
end

document procinfo
    Infos about the debugee.
end

define analyze
    procinfo
    printf "*\n* Threads (full) \n*\n"
    thread apply all bt full
end

define addrtosym
    if $argc == 1
        printf "[%u]: ", $arg0
        #whatis/ptype EXPR
        #info frame ADDR
        info symbol $arg0
    end
end

document addrtosym
    Resolve the address (e.g. of one stack frame). Usage: addrtosym addr0
end

#----------Logs-----------
define logenable
 set logging file gdb.log
 set logging on
end

define logdisable
 set logging off
end

#------Break Points-------
define bp
 break * $arg0
end

document bp
    Set Hardware Assisted breakpoint on address
    Usage: bp addr
end


define ib
    info breakpoints
end

document ib
    List breakpoints
end

define cb
    delete breakpoints
end

document cb
    Clear all breakpoints(no args) or at func/addr
    Usage: cb [addr]
end

define eb
    enable $arg0
end

document eb
    Enable breakpoint
    Usage: eb num
end

define db
    disable $arg0
end

document db
    Disable breakpoint
    Usage: db num
end

define wp
    awatch $arg0
end

document wp
    Set a read/write watch/break-point on address
    Usage: wp addr
end

#---------Utils-----------
define cls
 shell clear
end

document cls
Clears the screen with a simple command
end

#--------Process---------
define args
    show args
end

document args
    Print program arguments
end

define istack
    info stack
end

document istack
    Print call stack
end

define iframe
    info frame
    info args
    info locals
end

document iframe
    Print stack frame
end

define ireg
    #info registers
    info all-registers
end

document ireg
    Print CPU registers
end

define ifunc
    info functions
end

document ifunc
    Print functions in target
end

define ivar
    info variables
end

document ivar
    Print variables (symbols) in target
end

define ilib
    info sharedlibrary
end

document ilib
    Print shared libraries linked to target
end

define isig
    info signals
end

document isig
    Print signal actions for target
end

define ithr
    info threads
end

document ithr
    Print threads in target
end

define dis
    disassemble $arg0
end

document dis
    Disassemble address
    Usage: dis addr
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

document pm
    Displays the execution summary
end

#------Hex Dump-------
define ascii_char
    set $_c=*(unsigned char *)($arg0)
    if ( $_c < 0x20 || $_c > 0x7E )
        printf "."
    else
        printf "%c", $_c
    end
end

document ascii_char
    Print the ASCII value of arg0 or '.' if value is unprintable
end

define hex_quad
    printf "%02X %02X %02X %02X  %02X %02X %02X %02X",                  \
            *(unsigned char*)($arg0), *(unsigned char*)($arg0 + 1),      \
            *(unsigned char*)($arg0 + 2), *(unsigned char*)($arg0 + 3),  \
            *(unsigned char*)($arg0 + 4), *(unsigned char*)($arg0 + 5),  \
            *(unsigned char*)($arg0 + 6), *(unsigned char*)($arg0 + 7)
end

document hex_quad
    Print eight hexadecimal bytes starting at arg0
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

document hexdump
    Display a 16-byte hex/ASCII dump of arg0
end

define dump_to_file
    dump ihex memory $arg0 $arg1 $arg2
end

document dump_to_file
    Write a range of memory to a file in Intel ihex (hexdump) format.
    Usage:	dump_to_file filename start_addr end_addr
end

#------Read/Writes-------
define wbyte
 set * (unsigned char *) $arg0 = $arg1
end

document wbyte
Write byte at address arg0 to a given value/instruction
Usage: wbyte addr value/instr
end

define wword
 set * (unsigned short *) $arg0 = $arg1
end

document wword
Write word at address arg0 to a given value/instruction
Usage: wword addr value/instr
end

define wdword
 set * (unsigned long *) $arg0 = $arg1
end

document wdword
Write double word at address arg0 to a given value/instruction
Usage: wdword addr value/instr
end

