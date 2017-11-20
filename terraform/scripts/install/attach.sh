#!/bin/bash

set -euo pipefail

rlwrap sudo docker run -v /home/ubuntu/datadir:/datadir -it quorum attach /datadir/geth.ipc
