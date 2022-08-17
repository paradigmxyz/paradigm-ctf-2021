#!/bin/bash

IMAGE="gcr.io/paradigm-ctf/2021/$1:latest"
PORT="$2"
HTTP_PORT="$3"

echo "$ETH_RPC_URL"
if [ -z "$HTTP_PORT" ]; then
    echo "[+] running challenge"
    exec docker run \
        -e "SKIP_SECRET=secret" \
        -e "PORT=$PORT" \
        -p "$PORT:$PORT" \
        "$IMAGE"
else
    echo "[+] running eth challenge"
    exec docker run \
        -e "SKIP_SECRET=secret" \
        -e "PORT=$PORT" \
        -e "HTTP_PORT=$HTTP_PORT" \
        -e "ETH_RPC_URL=$ETH_RPC_URL" \
        -e "ENV=dev" \
        -p "$PORT:$PORT" \
        -p "$HTTP_PORT:$HTTP_PORT" \
        "$IMAGE"
fi