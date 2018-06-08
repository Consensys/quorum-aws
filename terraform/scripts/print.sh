#!/bin/bash

set -euo pipefail

cur=$(date +"%Y/%m/%d %H:%M:%S")

rlwrap sudo docker run -v /home/ubuntu/datadir:/datadir quorum --exec "'$cur      Block: ' + eth.blockNumber + ' | Peers: ' + admin.peers.length + ' | Pending: ' + txpool.status.pending + ' | Queued: ' + txpool.status.queued" attach /datadir/geth.ipc
