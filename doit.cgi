#!/usr/bin/env tclsh

set host 127.0.0.1
set host www.apple.com
set port 49900
after 2000 set state error
puts "connect to $host $port"
set chan [socket -async $host $port]
fileevent $chan w {set state connected}
vwait state
puts "state is $state"
switch $state {
  timeout {
    puts "timeout"
  }
  error {
    set msg [fconfigure $chan -error]
    puts "error $msg"
  }
  connected {
    set msg [fconfigure $chan -error]
    puts "error $msg"
    puts "connected"
    puts $chan "obo"
  }
  default {
    puts "default <$state>"
  }
}
