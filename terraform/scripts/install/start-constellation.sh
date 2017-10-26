#!/bin/bash

set -euo pipefail

my_gid=$(cat node-id)
my_port=$((9000 + $my_gid))
cluster_type=$(cat cluster-type)
num_subnets=$(cat num-subnets)

wait_for_peer() {
    gid=$1

    if [[ $cluster_type == "multi-region" ]]
    then
        port=$((9000 + $gid))
        endpoint="localhost:${port}"
    else
        #
        # TODO: we should read these URLs from the constellation config file,
        #       but it's TOML, which is hard to work with. if we read this from
        #       TOML then we can remove the num-subnets file; nothing else needs
        #       it.
        #
        idx=$(($gid-1))
        subnet=$((1 + ($idx % $num_subnets)))
        last_octet=$((101 + ($idx / $num_subnets)))
        port=$((9000 + $gid))
        endpoint="10.0.${subnet}.${last_octet}:${port}"
    fi

    until (curl -s "http://${endpoint}" >/dev/null); do
        echo "retrying connection to constellation ${gid} at ${endpoint} shortly"
        sleep 2
    done
    echo "successfully connected to constellation ${gid}"
}

echo "about to connect to previous constellations"

# Wait for all peers with a geth ID lower than $my_gid
for i in $(seq 1 $(($my_gid - 1))); do
    wait_for_peer $i
done

# Give the last-started constellation a few seconds to synchronize.
sleep 5

echo "starting constellation ${my_gid}"

# Start this constellation.

sudo docker run -d \
                -p ${my_port}:${my_port} \
                -v /home/ubuntu/datadir:/datadir \
                constellation \
                /bin/sh -c "constellation-node /datadir/constellation.toml"
