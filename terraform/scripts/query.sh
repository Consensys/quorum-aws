#!/bin/bash
#For querying the status of multiple blockchains.
HOSTS="[INSERT IP HERE]"

for HOSTNAME in ${HOSTS} ; do
    out=$(ssh -oStrictHostKeyChecking=no ubuntu@${HOSTNAME} "./print")
    echo "${HOSTNAME}        ${out}"
done
