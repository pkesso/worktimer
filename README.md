# worktimer
Simple work hours countdown for i3status-rs

Click it to run/pause

Configure it via env vars, if needed:

- WORKTIMER_WORKSECONDS - working hours in seconds (8 hours by default)
- WORKTIMER_STATEFILE - state file (your user must be able to write there)
- WORKTIMER_PIDFILE - pid file (your user must be able to write there)


~/.i3status-rs.toml sample:

    [[block]]
    block = "custom"
    command = "/usr/local/bin/worktimer.sh"
    cycle = ["/usr/bin/kill -s SIGUSR1 $(cat /run/user/$UID/worktimer.pid)"]
    persistent = true
    [[block.click]]
    button = "left"
    action = "cycle"

Don't forget to set correct path to worktimer.sh and worktimer.pid
