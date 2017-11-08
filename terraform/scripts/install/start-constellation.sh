#!/bin/bash

set -euo pipefail

my_gid=$(cat node-id)
my_port=$((9000 + $my_gid))

echo "starting constellation ${my_gid}"

sudo docker run -d \
                -p ${my_port}:${my_port} \
                -v /home/ubuntu/datadir:/datadir \
                constellation \
                /bin/sh -c "constellation-node /datadir/constellation.toml"
