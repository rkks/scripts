#-----------Init Control----------
#************Commands*************
define binit
 tbreak _init
 run
end

define bstart
 tbreak _start
 run
end

define bsstart
 tbreak __libc_start_main
 run
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
#*******Documentation*********
document binit
Run program; break on _init()
end

document bstart
Run program; break on _start()
end

document bsstart
Run program; break on __libc_start_main(). Useful for stripped executables.
end

document bmain
Run program; break on main()
end

document procinfo
Infos about the debugee.
end

document addrtosym
Resolve the address (e.g. of one stack frame). Usage: addrtosym addr0
end
#-----------Init Control----------

#----------Logs-----------
#************Commands*************
define logenable
 set logging file gdb.log
 set logging on
end

define logdisable
 set logging off
end
#----------Logs-----------

#------Break Points-------
#************Commands*************
define bp
 break * $arg0
end

define ib
 info breakpoints
end

define cb
 delete breakpoints
end

define eb
 enable $arg0
end

define db
 disable $arg0
end

define wp
 awatch $arg0
end

#*******Documentation*********
document bp
Set Hardware Assisted breakpoint on address
Usage: bp addr
end

document ib
List breakpoints
end

document cb
Clear all breakpoints(no args) or at func/addr
Usage: cb [addr]
end

document eb
Enable breakpoint
Usage: eb num
end

document db
Disable breakpoint
Usage: db num
end

document wp
Set a read/write watch/break-point on address
Usage: wp addr
end
#------Break Points-------

#---------Utils-----------
#************Commands*************
define cls
 shell clear
end

#**********Documentation**********
document cls
Clears the screen with a simple command
end
#---------Utils-----------

