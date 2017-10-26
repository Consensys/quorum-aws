#!/bin/bash

set -euo pipefail

gid=$(cat node-id)
p2p_port=$((30400 + $gid))
rpc_port=$((40400 + $gid))
raft_port=$((50400 + $gid))

echo "starting geth ${gid}"

sudo docker run -d -p $p2p_port:$p2p_port -p $rpc_port:$rpc_port -p $raft_port:$raft_port -v /home/ubuntu/datadir:/datadir -v /home/ubuntu/password:/password -e PRIVATE_CONFIG='/datadir/constellation.toml' quorum --datadir /datadir --port $p2p_port --rpcport $rpc_port --raftport $raft_port --networkid 1418 --verbosity 3 --nodiscover --rpc --rpccorsdomain "'*'" --rpcaddr '0.0.0.0' --raft --unlock 0 --password /password
