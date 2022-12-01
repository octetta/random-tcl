set state error
after 5000 set state timeout
set h [socket -async www.apple.com 8080]
fileevent $h w {set state connected}
vwait state

puts $state
