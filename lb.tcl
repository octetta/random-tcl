package require Tk
#This is based on browser program from John Ousterhout
#It allows files to be selected for editing.
#Double click selection on text file initiates editing.
#Double click selection on directory initiates new browser.


if {$argc >0} {set dir [lindex $argv 0]} else {set dir "."}
wm title . "Directory : $dir"


#Set editor program - to editor of choice
set editor "edit25.tcl"


frame .f1
scrollbar .f1.scrollit -command ".f1.list yview"


listbox .f1.list -yscroll ".f1.scrollit set" -relief raised
# -geometry 20x20
pack .f1.scrollit -side right -fill y
pack .f1.list -side left -expand yes -fill both


#pack listbox above button
button .button1 -text "QUIT" -command {destroy .}
pack .f1 .button1 -fill x


proc browse {dir file} {
    global editor
    puts $dir
    puts $file
    if  {{[ string compare $dir "."]} !=0} {set file $dir/$file}
    if [file isdirectory $file] {
	exec browse $file &
    } else {
       if [file isfile $file] {
	   exec $editor $file &
	} else {
	   puts "$file isn't a directory or regular file\n"
	   }
      }
 }


foreach i [exec ls -a $dir] {
     .f1.list insert end $i
}


bind .f1.list <Control-q> {destroy .}
bind .f1.list <Control-c> {destroy .}
bind .f1.list <Double-Button-1> {foreach i [selection get]  
	{browse $dir $i}}
focus .f1.list