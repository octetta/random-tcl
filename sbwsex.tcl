# general purpose slack bot package

package require http
package require tls
package require json
package require websocket


namespace eval slackbot {
    # users, channels and messages cache
    variable USERS {}
    variable CHANNELS {}
    variable MESSAGES {}

    # pending messages (sent with ::slackbot::send_message)
    variable PENDING_MSG {}

    # Slack server event handlers
    variable EVENT_HANDLERS {}

    # this bot's user ID
    variable myself {}

    # ephemeral websocket URI
    variable ws_url {}

    # websocket handler
    variable ws {}

    # client -> server message id
    variable msgid 0

    # the bot's auth token
    variable token {}

    # Emoji list
    variable _emojilist {
        sparkles pizza sunglasses palm_tree dog ghost dragon cool squirrel
        wolf cat lion_face tiger leopard horse deer cow ox boar sheep goat
        camel elephant mouse hamster rabbit chipmunk koala penguin octopus
        owl crocodile frog whale fish duck crab butterfly bee beetle sunny
        sunflower rose sunrise ferris_wheel fire_engine bike ship airplane
        anchor rocket stars floppy_disk bulb ledger hammer wrench shield
    }
}

    ##########################
    ## SLACK RTM CONNECTION ##
    ##########################

# slack_rtm_start: calls rtm.start
#   should be called once at startup or if the ws URI becomes invalid
#
# side effects:
#   - populates the USERS cache
#   - sets ::ws_url value
proc ::slackbot::rtm_start {} {
    variable USERS
    variable CHANNELS
    variable myself
    variable ws_url
    variable token

    if {![info exists ::slackbot::tlsInit]} {
        set ::slackbot::tlsInit true
        ::tls::init -tls1 1
        http::register https 443 ::tls::socket
    }

    set start_res [
        ::json::json2dict [
            ::http::data [
                ::http::geturl "https://slack.com/api/rtm.start?token=$token"
            ]
        ]
    ]

    puts "-> $start_res"

    if {![dict get $start_res ok]} {
        return false
    }

    set ws_url [dict get $start_res url]
    set myself [dict get [dict get $start_res self] id]

    # reset the cache
    set USERS {}
    set CHANNELS {}

    foreach user [dict get $start_res users] {
        dict set USERS [dict get $user id] $user
    }

    foreach channel [dict get $start_res channels] {
        dict set CHANNELS [dict get $channel id] $channel
    }

    return true
}

# connects to Slack RTM websocket server
#
# if the ws_url variable is empty, calls rtm.start to get a ephemeral URI
proc ::slackbot::connect {} {

    variable ws_url
    variable ws
    variable token

    if {[info exists ws] && $ws ne ""} {
        return
    }

    if {$ws_url eq {}} {
        rtm_start
    }

    if {$ws_url eq {}} {
puts "Trying again after 5s"
        after 5000 {
            ::slackbot::connect
        }
        return
    }

    unset -nocomplain ::slackbot::ws_keepalive
    set ws [::websocket::open $ws_url ::slackbot::ws_handler]
puts "Opened WS: $ws"
}

proc ::slackbot::disconnect {} {
    variable ws_url
    variable ws

    unset -nocomplain ::slackbot::ws_keepalive

    if {![info exists ws] || $ws eq ""} {
        return
    }

puts "Closing $ws"
    catch {
        ::websocket::close $ws
    }
    set ws ""
    set ws_url ""
}

# event handler for slack RTM's websocket
proc ::slackbot::ws_handler {sock type msg} {
    variable PENDING_MSG
puts "WS event: $sock $type $msg"
    switch -- $type {
        text {
            set event [::json::json2dict $msg]

            # generate a "fake" message event if the message is a positive
            # reply to a sent message  
            if {[dict exists $event reply_to]} {
                set id [dict get $event reply_to]
                if {[dict exists $event ok]
                        && [dict get $event ok] eq "true"
                        && [dict exists $PENDING_MSG $id]} {
                    set event [
                        dict merge [dict get $PENDING_MSG $id] $event
                    ]
                    dict unset PENDING_MSG $id
                } else {
                    return
                }
            }

            # call event handlers
            dispatch_event [dict get $event type] $event
        }
        disconnect {
            keepalive 0
            after 1000 ::slackbot::connect
        }
        connect - pong {
            keepalive 60
        }
    }
}

proc ::slackbot::keepalive {time_s} {
    variable ws

    if {![info exists ws] || $ws eq ""} {
        return
    }

    if {[info exists ::slackbot::pong_timer]} {
        after cancel $::slackbot::pong_timer
        unset ::slackbot::pong_timer
    }

    set set_keepalive true
    if {$time_s eq ""} {
        set set_keepalive false

        if {![info exists ::slackbot::ws_keepalive]} {
            return
        }

        set time_s $::slackbot::ws_keepalive
    }

    if {$time_s == 0} {
        return
    }

    if {$set_keepalive} {
        ::websocket::configure $ws -keepalive $time_s
        set ::slackbot::ws_keepalive $time_s
    }

    set ::slackbot::pong_timer [
        after [expr {$time_s * 1000 * 4}] [list apply {{} {
            puts "Keepalive Timeout reached"
            unset -nocomplain ::slackbot::pong_timer
            ::slackbot::disconnect
            ::slackbot::connect
	}}]
    ]
}

    ###############
    ## EVENT API ##
    ###############

# registers an event handler
# params:
#   - event_type: event type (ex: "message", "reaction_added", ...)
#   - code:       the code to execute upon reception of this event
proc ::slackbot::on_event {event_type code} {
    variable EVENT_HANDLERS
    dict lappend EVENT_HANDLERS $event_type $code

    # Reset keepalive upon data being received
    keepalive ""
}

# call all the registered handlers
# params:
#   - event_type: event type (ex: "message", "reaction_added", ...)
#   - event:      dictionnary containig all the details about the event
proc ::slackbot::dispatch_event {event_type event} {
puts stderr "Got: event $event_type: $event"
    variable EVENT_HANDLERS
    if {[dict exists $EVENT_HANDLERS $event_type]} {
        foreach code [dict get $EVENT_HANDLERS $event_type] {
            event_cb_wrapper $code $event
        }
    }
}

# isolate and prepare the execution context of an event handler
proc ::slackbot::event_cb_wrapper {code event} {
    # define all the variables that will be made available in the handler's
    # code
    dict for {k v} $event {
        set $k $v
    }
    unset k
    unset v
    eval $code
}

## some builtin event handlers

# memorize the new ephemeral WS URI
::slackbot::on_event reconnect_url {
    variable ws_url
    set ws_url [dict get $event url]
}

::slackbot::on_event error {
    variable ws_url
    # reconnect if the WS URI was invalid
    if {[dict get [dict get $event error] code] eq 1} {
        set ws_url {}
        after 1000 {
            ::slackbot::disconnect
            ::slackbot::connect
        }
    }
}

# Handle new users
::slackbot::on_event team_join {
    variable USERS
    dict set USERS [dict get $user id] $user
}

# Handle changes to users
::slackbot::on_event user_change {
    variable USERS
    dict set USERS [dict get $user id] $user
}


    ##################
    ## SLACKBOT API ##
    ##################

# stores a Slack message in the cache
# params:
#   - message: the Slack message object (dictionnary)
#   - timeout: lifetime of this entry in the cache (forever if == 0)
proc ::slackbot::cache_message {message timeout} {
    variable MESSAGES
    set channel [dict get $message channel]
    set ts [dict get $message ts]
    dict set MESSAGES "$channel-$ts" $message
    if {$timeout > 0} {
        after $timeout [list ::slackbot::cached_message_expired $message]
    }
}

# called internally when a message has expired in the cache
proc ::slackbot::cached_message_expired {message} {
    variable MESSAGES
    set channel [dict get $message channel]
    set ts [dict get $message ts]
    dict unset MESSAGES "$channel-$ts"
    # trigger an event
    dispatch_event message_cache_expires $message
}


## a few getters

proc ::slackbot::get_user id {
    variable USERS
    if {[dict exists $USERS $id]} {
        return [dict get $USERS $id]
    } else {
        return {}
    }
}

proc ::slackbot::get_users {} {
    variable USERS
    return $USERS
}

proc ::slackbot::get_channel id {
    variable CHANNELS
    if {[dict exists $CHANNELS $id]} {
        return [dict get $CHANNELS $id]
    } else {
        return {}
    }
}

proc ::slackbot::get_channels {} {
    variable CHANNELS
    return $CHANNELS
}

proc ::slackbot::get_message {channel ts} {
    variable MESSAGES
    if {[dict exists $MESSAGES "$channel-$ts"]} {
        return [dict get $MESSAGES "$channel-$ts"]
    } else {
        return {}
    }
}

proc ::slackbot::is_myself uid {
    variable myself
    return [expr {"$uid" eq "$myself"}]
}

## RTM client->server calls (only sending messages is supported right now)

proc ::slackbot::_userNameToId {userName} {
	foreach {userId userInfo} [get_users] {
		set checkUserName [dict get $userInfo profile display_name]
		if {$checkUserName eq ""} {
			set checkUserName [dict get $userInfo profile real_name]
		}

		if {$userName ne $checkUserName} {
			continue
		}

		return $userId
	}

	return ""
}

proc ::slackbot::send_message {channel msg {setUser ""}} {
    variable PENDING_MSG
    variable ws
    variable myself
    variable msgid
    variable token
    set esc_msg [string map {\n \\n \r \\r \\ \\\\ \" \\\"} $msg]

    if {$setUser eq ""} {
        set struct "{
            \"id\": \"[incr msgid]\",
            \"type\": \"message\",
            \"channel\": \"$channel\",
            \"text\": \"$esc_msg\"
        }"

        ::websocket::send $ws text $struct
        dict set PENDING_MSG $msgid {type message channel $channel user $myself}

        return $msgid
    } else {
        set esc_setUser [string map {\n \\n \r \\r \\ \\\\ \" \\\"} $setUser]
        set setUserId [_userNameToId $setUser]
        if {$setUserId ne ""} {
            catch {
                set icon_setUser [dict get [get_user $setUserId] profile image_48]
                set icon_setUserMode "url"
            }
        }

        if {![info exists icon_setUser]} {
            set icon_setUser :[lindex $::slackbot::_emojilist [expr "entier(srand(0x[binary encode hex $setUser]) * [llength $::slackbot::_emojilist])"]]:
            set icon_setUserMode "emoji"
        }

        set struct "{
            \"token\": \"$token\",
            \"channel\": \"$channel\",
            \"text\": \"$esc_msg\",
            \"as_user\": false,
            \"icon_${icon_setUserMode}\": \"$icon_setUser\",
            \"username\": \"$esc_setUser\"
        }"
	catch {
            http::geturl https://slack.com/api/chat.postMessage -headers [list Authorization "Bearer $token"] -binary true -query [encoding convertto utf-8 $struct] -type {application/json; charset=utf-8} -command [list apply {{httpObject args} {
                http::cleanup $httpObject
            }}]
        }
    }
}

package provide slackbot 1.0