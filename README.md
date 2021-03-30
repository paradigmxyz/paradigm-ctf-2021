# CTF Data

## Installing

### Prerequisites

* Docker
* [solc-select](https://github.com/crytic/solc-select)
* [mpwn](https://github.com/lunixbochs/mpwn)
* Python 3

### Configuration

You'll need to update the following environment variables:
* `RPC_URL` to a valid Ethereum JSON-RPC endpoint
* `PYTHONPATH` to point to mpwn

You'll also need to manually install the following:
* `solc-select install 0.4.16 0.4.24 0.5.12 0.6.12 0.7.0 0.7.6 0.8.0`
* `pip install ecdsa sha3`

### Build everything

```bash
./build
```

### Run a challenge

Running a challenge will open a port which users will `nc` to. For Ethereum related
challenges, an additional port must be supplied so that users can connect to the Ethereum
node (which forks from mainnet state)

```
./run babycrypto 31337
```

On another terminal:

```
nc localhost 31337
```

For ETH challenges:

```
./run bank 31337 8545
```

## Running the autosolver

```bash
./solve
```

## Add a new challenge

1. Copy one of the existing challenge directories and rename it to your challenge's name
1. Edit the `info.yaml` to add your details
1. Add your contracts under the `public/contracts` directory
1. Add any contracts which are supposed to be private, such as the source code for a rev challenge
or a challenge solution under the `contracts/private` directory
1. Add it to the build script with the dirname and compiler version
1. (Optional) Allow it to be auto-solved:
    1. Do either of the following:
        * Add an `private/Exploit.sol` file with a `constructor(Setup setup)` constructor that solves the challenge
        * Add a `private/solve.py` if it requires additional actions to be executed (e.g. babycrypto, vault)
    1. Then add it to the `solve` script

