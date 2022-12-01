package require Tk
canvas .c -width 12c -height 1.5c
pack .c
.c create line 1c 0.5 1c 1c 11c 1c 11c 0.5c
for {set i 0} {$i < 10} {incr i} {
set x [expr $i+1]
.c create line ${x}c 1c ${x}c 0.6c
.c create line ${x}.25c 1c ${x}.25c 0.8c
.c create line ${x}.5c 1c ${x}.5c 0.7c
.c create line ${x}.75c 1c ${x}.75c 0.8c
.c create text ${x}.15c .75c -text $i -anchor sw
}
# wm title . "ruler"
# wm iconify .w
# wm iconify .
# wm restore .
# wm deiconify .
# wm restore .
# wm iconify .
# wm deiconify .
