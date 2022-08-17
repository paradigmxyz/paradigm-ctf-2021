#!/bin/bash

set -euo pipefail

function solve_one() {
    CHAL="$1"
    VERSION="${2:-}"
    ETH="${3:-0}"
    REMOTE_IP="127.0.0.1"
    REMOTE_PORT="31337"

    echo "[+] solving $CHAL"

    ./run.sh "$CHAL" "31337" "8080" >/dev/null 2>&1 &
    CHAL_PID="$!"
    function cleanup()
    {
        kill "$CHAL_PID"
    }

    trap cleanup EXIT

    sleep 2

    pushd "$CHAL/private" >/dev/null

    if [ -z "$VERSION" ]; then
        REMOTE_IP="$REMOTE_IP" REMOTE_PORT="$REMOTE_PORT" python3 solve.py
    else
        if [ -f "solve.py" ]; then
            file="solve.py"
        else
            file="../../private/paradigmctf/eth_challenge.py"
        fi
        PYTHONDONTWRITEBYTECODE=1 PYTHONPATH="$PYTHONPATH:../../private" SOLC_VERSION=$VERSION REMOTE_IP="$REMOTE_IP" REMOTE_PORT="$REMOTE_PORT" DEPLOY_ETH=$ETH python3 $file
    fi

    popd >/dev/null

    kill "$CHAL_PID"
}

declare -a chals=(
    "babycrypto"
    "bank 0.4.24"
    "vault 0.4.16"
    "lockbox 0.4.24"
    "babysandbox 0.7.0"
    "market 0.7.0 20"
    # "upgrade 0.6.12" # unsolvable lol
    "secure 0.5.12 50"
    "jop 0.7.6 1"
    "rever 0.8.0 1"
    "swap 0.4.24 1000"
    "babyrev 0.4.24"
    "bouncer 0.8.0 100"
    "hello 0.8.0"
    "farmer 0.8.0 100"
    "yield_aggregator 0.8.0"
    "broker 0.8.0 50"
)

for chal in "${chals[@]}"; do
    solve_one $chal
done
