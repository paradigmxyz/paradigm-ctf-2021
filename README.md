# Paradigm CTF 2021

## Installing

### Prerequisites

* Docker
* [solc-select](https://github.com/crytic/solc-select)
* [mpwn](https://github.com/lunixbochs/mpwn)
* Python 3

### Configuration

You'll need to set the following environment variables:
* `ETH_RPC_URL` to a valid Ethereum JSON-RPC endpoint
* `PYTHONPATH` to point to mpwn

You'll also need to manually install the following:
* `pip install ecdsa pysha3 web3`

## Usage

### Build everything

```bash
./build.sh
```

### Run a challenge

Running a challenge will open a port which users will `nc` to. For Ethereum related
challenges, an additional port must be supplied so that users can connect to the Ethereum
node (which forks from mainnet state)

```
./run.sh babycrypto 31337
```

On another terminal:

```
nc localhost 31337
```

For ETH challenges:

```
./run.sh bank 31337 8545
```

When prompted for the hashcash PoW, use the default secret `secret`:

```
$ nc localhost 31337
1 - launch new instance
2 - get flag
action? 1
hashcash -mb24 gdrfjbxs = ? secret

your private blockchain has been deployed
it will automatically terminate in 30 minutes
here's some useful information
```

### Running the autosolver

```bash
./solve.sh
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

