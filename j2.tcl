set http_ver [package require http]
puts "http version $http_ver"

set ws_ver [package require websocket]
puts "websocket version $ws_ver"

::websocket::loglevel debug

proc handler {sock type msg} {
    puts "type -> $type"
    switch -- $type {
        connect - pong {
            puts "connect/pong"
        }
        disconnect {
            puts "disconnect"
        }
        text {
            puts "text -> $msg"
        }
    }
}

#set url ws://echo.websocket.org/?encoding=text
#set url ws://echo.websocket.org/
# set url ws://echo.websocket.org
set url ws://127.0.0.1:8080/ws

set ws [::websocket::open $url handler]

proc listen {when} {
    set ender 1
    after $when set ender 0
    vwait ender
}

proc send {sock msg} {
    ::websocket::send $sock text $msg
}

listen 400

send $ws "ponderosa"
send $ws "funderosa"
send $ws "sunderosa"