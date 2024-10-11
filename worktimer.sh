#!/bin/bash

# https://docs.rs/i3status-rs/latest/i3status_rs/blocks/custom/index.html

#set -e
#set -x
#DEBUG=true

# TODO fix reset counter on date change
# TODO human-readable date in statefile?
# TODO colored panel?

# start paused
PAUSE=1

# 
config() {
    if [ "$DEBUG" ]; then echo 'Configuring'; fi
    DEFAULT_WORKSECONDS="$(( 8*3600 ))"    # 8h
    DEFAULT_STATEFILE="$HOME/.worktimer.state"
    DEFAULT_PIDFILE="/run/user/$UID/worktimer.pid"
    
    if [ -z "$WORKTIMER_WORKSECONDS" ]
    then
        WORKSECONDS="$DEFAULT_WORKSECONDS"
    else
        WORKSECONDS="$WORKTIMER_WORKSECONDS"
    fi

    if [ -z "$WORKTIMER_STATEFILE" ]
    then
        STATEFILE="$DEFAULT_STATEFILE"
    else
        STATEFILE="$WORKTIMER_STATEFILE"
    fi

    if [ -z "$WORKTIMER_PIDFILE" ]
    then
        PIDFILE="$DEFAULT_PIDFILE"
    else
        PIDFILE="$WORKTIMER_PIDFILE"
    fi
}

# try to use previous data from state file
try-resume() {
    if [ "$DEBUG" ]; then echo 'Trying to resume from state file'; fi
    if [ -f "$STATEFILE" ]
    then
        STATE=$(cat "$STATEFILE") || return 0
        STATETIME=$(echo "$STATE" | cut -f 1 -d ' ') || return 0
        STATEWORKSECONDS=$(echo "$STATE" | cut -f 2 -d ' ') || return 0
        # echo "Statetime $STATETIME Stateworkseconds $STATEWORKSECONDS"
        if [ "$DEBUG" ]
            then
            echo "State in file found: STATETIME $(date -d @"$STATETIME" +%Y/%m/%d_%H-%M-%S) STATEWORKSECONDS $(date "+%s") $WORKSECONDS"
        fi
        if [ "$(date -d @"$STATETIME" +%Y%m%d)" == "$(date +%Y%m%d)"  ]
        then
            # echo 'Same day, resuming timer'
            if [ "$DEBUG" ]; then echo 'Same day, resuming counter'; fi
            WORKSECONDS=$STATEWORKSECONDS
        else
            if [ "$DEBUG" ]; then echo 'New day, resetting counter'; fi
            return 0
        fi
    fi
}

# invert pause
pause-unpause() {
    # send SIGUSR1 to the process to pause timer
    # kill -s SIGUSR1 $(cat $PIDFILE)
    ((PAUSE ^= 1 ))
    if [ $PAUSE -eq 0 ]
    then
        if [ "$DEBUG" ]; then echo 'Unpausing'; fi
        try-resume
    else
        if [ "$DEBUG" ]; then echo 'Pausing'; fi
    fi
}

# cleanup and exit
cleanup() {
    if [ "$DEBUG" ]; then echo 'Cleaning up'; fi
    rm -f "$PIDFILE"
    exit 0
}

# main loop
main() {
    if [ "$DEBUG" ]; then echo 'Entering main loop'; fi
    echo "$$" > "$PIDFILE"
    while true
        do
            sleep 1
            if [ "$PAUSE" -eq 0 ]
            then
                ((WORKSECONDS--))
                if [ "$WORKSECONDS" -lt 0 ]
                then
                    # overtime mode
                    if [ "$DEBUG" ]
                    then
                        echo 'Overtime mode'
                        echo "-$(date -d@$((WORKSECONDS * -1)) -u +%H:%M:%S)"
                    else
                        echo "-$(date -d@$((WORKSECONDS * -1)) -u +%H:%M)"
                    fi
                else
                    # normal mode
                    if [ "$DEBUG" ]
                    then
                        echo 'Normal mode'
                        date -d@$WORKSECONDS -u +%H:%M:%S
                    else
                        date -d@$WORKSECONDS -u +%H:%M
                    fi
                fi
                echo "$(date "+%s") $WORKSECONDS" > "$STATEFILE"
            else
                echo '[paused]'
            fi
        done
}

if [ "$DEBUG" ]; then echo 'DEBUG is on'; fi
config
trap pause-unpause SIGUSR1
trap cleanup SIGINT
main
