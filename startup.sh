#!/bin/bash

# the name of your primary tmux session
SESSION=$USER
# your IRC nickname
IRC_NICK=$USER
 
sleep 10

# if the session is already running, just attach to it.
tmux has-session -t $SESSION
if [ $? -eq 0 ]; then
    echo "Session $SESSION already exists. Attaching."
    sleep 1
    tmux attach -t $SESSION
    exit 0;
fi
 
# create a new session, named $SESSION, and detach from it
tmux new-session -s $SESSION -n welcome "/home/bootstrap/bin/homescreen.sh"
