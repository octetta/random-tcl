package require Tk
#This is a skeleton for a very simple editor, written using
   #TCL with TK widgets.


   #The editor "looks" like a simple package, but none of the
   #procedures actually work.


   #set up a frame for menubar


   frame .mb
   menubutton .mb.button1 -text "File" -relief raised -menu .mb.button1.m
   menubutton .mb.button2 -text "Edit" -relief raised -menu .mb.button2.m


   #pack .mb.button1 .mb.button2  -side left  -padx 2m -fill x -expand yes
   pack .mb.button1 .mb.button2  -side left  -fill x -expand yes


   menu .mb.button1.m
   menu .mb.button2.m


   .mb.button1.m add command -label "New..." -command {NewFile}
   .mb.button1.m add command -label "Load ..." -command {LoadFile}
   .mb.button1.m add command -label "Append..." -command {AppendFile}
   .mb.button1.m add command -label "Save" -command {SaveFile}
   .mb.button1.m add command -label "Save As..." -command {SaveAsFile}
   .mb.button1.m add command -label "Quit" -command {QuitFile}


   .mb.button2.m add command -label "Clear" -command {ClearEdit}


   #set up a frame for text edit
   frame .te -relief raised -borderwidth 2


   #Shows how to control text widget scrolling using
   #a scrollbar


   #set geometry to give a reasonable window size
   # . configure  -geometry 80x30


   #First set up scrollbar
   scrollbar .te.vscroll -relief sunken -command ".te.edit1 yview"


   #Set up a text widget and link scroll
   text .te.edit1 -yscroll ".te.vscroll set"


   #Pack editing components


   pack .te.vscroll  -side right -fill y
   pack .te.edit1 -expand yes -fill y


   #Now pack everything together
   pack .mb .te  -pady 2m -fill x


   proc NewFile {} {
    puts "NewFile not implemented yet"
    }


   proc LoadFile {} {
    puts "LoadFile not implemented yet"
    }


   proc AppendFile {} {
    puts "AppendFile not implemented yet"
    }


   proc SaveFile {} {
    puts "SaveFile not implemented yet"
    }


   proc SaveAsFile {} {
    puts "SaveAsFile not implemented yet"
    }


   proc QuitFile {} {
    puts "QuitFile not implemented yet"
    }


   proc ClearEdit {} {
    puts "ClearEdit not implemented yet"
    }