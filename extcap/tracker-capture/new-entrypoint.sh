#!/bin/sh

handler()
{
    kill -s SIGINT $PID
}

/tracker/entrypoint.sh $@ &
PID=$!

trap handler SIGINT SIGTERM
wait $PID

chmod -R g+w /output