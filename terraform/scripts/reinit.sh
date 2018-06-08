#!/bin/bash

set -euo pipefail

#
cluster_size=$2
local_data_root=$1
terra_root=$(pwd)

GOPATH=$terra_root
GOPATH+="/go"
echo $terra_root
export GOPATH

nodekeys=""
iterator="1"
while [ $iterator -le ${cluster_size} ]
do
  nodekey=$(cat $(pwd)/$local_data_root/geth$iterator/geth/nodekey)
  nodekeys+=$nodekey
  nodekeys+=" "
  iterator=$((iterator+1))
done

#Calling istnabul tools
go run $GOPATH/src/github.com/reinit-tools/main.go ${nodekeys} > ${terra_root}/${local_data_root}/genesis.json
echo "Reinitialization of genesis is complete"




