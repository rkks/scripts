set logging file $gdblogfile
set logging on
set pagination off
printf \"**\n** Process info for PID=$pid \n** Generated `date`\n\"
where
info proc
printf \"*\n* Libraries \n*\n\"
info sharedlib
printf \"*\n* Memory map \n*\n\"
info target
printf \"*\n* Registers \n*\n\"
info registers
printf \"*\n* Current instructions \n*\n\"" -ex "x/16i \$pc
printf \"*\n* Threads (full) \n*\n\"
info threads
bt
thread apply all bt full
printf \"*\n* Threads (basic) \n*\n\"
info threads
thread apply all bt
printf \"*\n* Done \n*\n\"
generate-core-file $corefile
detach
quit"
