#!/bin/bash

# https://docs.rs/i3status-rs/latest/i3status_rs/blocks/custom/index.html

#set -e
#set -x

# TODO переход счетчика через ноль - сбрасывает на 23:59, а должен показывать счетчик переработки (с минусом?)
# TODO colored panel?

# start paused
PAUSE=1

# 
config() {
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
    if [ -f "$STATEFILE" ]
    then
        STATE=$(cat "$STATEFILE") || return 0
        STATETIME=$(echo "$STATE" | cut -f 1 -d ' ') || return 0
        STATEWORKSECONDS=$(echo "$STATE" | cut -f 2 -d ' ') || return 0
        # echo "Statetime $STATETIME Stateworkseconds $STATEWORKSECONDS"
        if [ "$(date -d @"$STATETIME" +%Y%m%d)" == "$(date +%Y%m%d)"  ]
        then
            # echo 'Same day, resuming timer'
            WORKSECONDS=$STATEWORKSECONDS
        else
            # echo 'New day, resetting timer'
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
        try-resume
    fi
}

# cleanup and exit
cleanup() {
    rm -f "$PIDFILE"
    exit 0
}

# main loop
main() {
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
                    #echo "-$(date -d@$((WORKSECONDS * -1)) -u +%H:%M:%S)"
                    echo "-$(date -d@$((WORKSECONDS * -1)) -u +%H:%M)"
                else
                    #date -d@$WORKSECONDS -u +%H:%M:%S
                    date -d@$WORKSECONDS -u +%H:%M
                fi
                echo "$(date "+%s") $WORKSECONDS" > "$STATEFILE"
            else
                echo '[paused]'
            fi
        done
}

config
trap pause-unpause SIGUSR1
trap cleanup SIGINT
main
