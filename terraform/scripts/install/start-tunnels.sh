#!/bin/bash

set -e
set -u

my_gid=$(cat node-id)
cluster_type=$(cat cluster-type)
cluster_size=$(cat cluster-size)
phrase="tunnel to geth" # phrase we use in output, and also look for via grep

die() {
    echo >&2 "ERROR: $@"
    exit 1
}

print_usage() {
    die "usage: start-tunnels [eip0 eip1 ...]"
}

[ "$#" -ne "${cluster_size}" ] && print_usage

eips=("$@")

start_tunnel() {
    gid=$1
    eip=$2
    port=$3

    echo "starting tunnel to geth ${gid} at ${eip}:${port}"

    # I couldn't figure out how to get docker to cooperate with starting an SSH tunnel inside of it, so we use nohup and background for now:
    nohup bash -c "until (ssh -M -T -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i .ssh/tunnel -N -L 0.0.0.0:${port}:localhost:${port} ubuntu@${eip}); do echo 're-establishing $phrase ${gid}:${port}'; done" >/dev/null 2>/dev/null </dev/null &
}

start_tunnels() {
    gid=$1
    eip=$2

    start_tunnel $gid $eip "3040${gid}" # Ethereum P2P
    start_tunnel $gid $eip "5040${gid}" # Raft HTTP
    start_tunnel $gid $eip "900${gid}"  # Constellation
}

if [[ $cluster_type == "multi-region" ]]
then
    if [[ $(ps aux | grep -v grep | grep "$phrase" | wc -l) -ne 0 ]]
    then
        echo "it looks like tunnels are already running"
    else
        echo "starting cross-region tunnels"

        for ((i = 0; i < ${#eips[@]}; ++i))
        do
            their_gid=$(($i + 1))

            if [[ "${my_gid}" != "${their_gid}" ]]
            then
                eip=${eips[$i]}
                start_tunnels "${their_gid}" "${eip}"
            fi
        done
    fi
else
    die "not starting tunnels because this is a single-region cluster."
fi
