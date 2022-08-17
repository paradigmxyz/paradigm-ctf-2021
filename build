#!/bin/bash

set -euo pipefail

build_challenge() {
    name="$1"
    solcv="${2:-}"

    tag="gcr.io/paradigm-ctf/2021/$name:latest"

    if [ ! -z "$solcv" ]; then
        pushd "$name/public"
        ROOT_DIR="$(cd .. && pwd)"
        if ! solc-select versions | grep "$solcv" >/dev/null 2>&1; then
            solc-select install "$solcv"
        fi
        SOLC_VERSION="$solcv" solc "private=$ROOT_DIR/private/" "public=$ROOT_DIR/public/contracts" --combined-json bin contracts/Setup.sol > deploy/compiled.bin
        sed -i.bak "s^${ROOT_DIR}^^g" deploy/compiled.bin && rm deploy/compiled.bin.bak
        popd
    fi

    docker build -t "$tag" "$name/public"

    if [ ! -z "${DEPLOY:-}" ]; then
        docker push "$tag"
    fi
}

declare -a chals=(
    "babycrypto"
    "bank 0.4.24"
    "vault 0.4.16"
    "lockbox 0.4.24"
    "babysandbox 0.7.0"
    "market 0.7.0"
    "upgrade 0.6.12"
    "secure 0.5.12"
    "jop 0.7.6"
    "rever 0.8.0"
    "swap 0.4.24"
    "babyrev 0.4.24"
    "bouncer 0.8.0"
    "hello 0.8.0"
    "farmer 0.8.0"
    "yield_aggregator 0.8.0"
    "broker 0.8.0"
)

for chal in "${chals[@]}"; do
    build_challenge $chal
done
