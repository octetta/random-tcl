proc connect {where} {
    global ssh
    set ssh [open "|ssh $where" "r+"] ;# start up the remote shell, should be tclsh
    fconfigure $ssh -buffering line -blocking 1

    # set up a command loop which processes and returns our commands
    puts $ssh {
            fconfigure stdout -buffering line
            while {![eof stdin]} {
                set cmd [gets stdin]
                set code [catch $cmd result opt]
                puts [string map [list \\ \\\\ \n \\n] $opt]
                puts [string map [list \\ \\\\ \n \\n] $result]
            }
    }

    # return the ssh connection
    return $ssh
}