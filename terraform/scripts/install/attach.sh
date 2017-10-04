#!/bin/bash

set -euo pipefail

sudo docker run -v /home/ubuntu/datadir:/datadir -it quorum attach /datadir/geth.ipc
