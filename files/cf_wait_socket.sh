#!/bin/sh

port=$1
timeout=${2:-180}

for i in $(seq 1 $timeout); do
    if /bin/netstat -tln | /bin/grep -q ":${port}"; then
        exit 0
    else
        sleep 1
    fi
done

exit 1
