#!/bin/sh

set -x

if [ -z "${CORES}" ]; then
export CORES=`grep -c processor /proc/cpuinfo`
fi

envtpl /app/xmr-stak-cpu.config.tpl -o /app/config.txt --allow-missing --keep-template
envtpl /app/xmr-stak-cpu.cpu.tpl -o /app/cpu.txt --allow-missing --keep-template
envtpl /app/xmr-stak-cpu.pools.tpl -o /app/pools.txt --allow-missing --keep-template

if [ "$1" = 'xmr-stak-cpu' ]; then
    exec /app/xmr-stak --cpu /app/cpu.txt -c /app/config.txt -C /app/pools.txt
fi

exec "$@"
