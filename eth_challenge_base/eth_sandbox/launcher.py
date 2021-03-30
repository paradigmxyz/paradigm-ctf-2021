import requests
import os
from dataclasses import dataclass
from typing import Callable, List, Dict, Optional
import binascii
import random
import string
from eth_sandbox import hashcash

from web3 import Web3
from web3.types import TxReceipt
from eth_account import Account
import json

from eth_sandbox import load_auth_key
from hexbytes import HexBytes

from uuid import UUID

HTTP_PORT = os.getenv("HTTP_PORT", "8545")
INTERNAL_URL = os.getenv("INTERNAL_URL", f"http://127.0.0.1:{HTTP_PORT}")
PUBLIC_URL = os.getenv("PUBLIC_URL", f"http://127.0.0.1:{HTTP_PORT}")

if os.getenv("ENV", "prod") == "prod":
    IP = requests.get(
        "http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/access-configs/0/external-ip",
        headers={
            "Metadata-Flavor": "Google",
        },
    ).text

    PUBLIC_URL = f"http://{IP}:{HTTP_PORT}"

Account.enable_unaudited_hdwallet_features()


@dataclass
class Action:
    name: str
    handler: Callable[[], int]

GANACHE_UNLOCK = "evm_unlockUnknownAccount"
GANACHE_LOCK = "evm_lockUnknownAccount"

HARDHAT_UNLOCK = "hardhat_impersonateAccount"
HARDHAT_LOCK = "hardhat_stopImpersonatingAccount"

def send_tx(web3: Web3, tx: Dict, deployer: str, is_hardhat: Optional[bool]) -> Optional[TxReceipt]:
    if "gas" not in tx:
        tx["gas"] = 9_500_000

    if "gasPrice" not in tx:
        tx["gasPrice"] = 0

    if "to" in tx and tx["to"] == "deployer":
        tx["to"] = deployer

    if tx["from"] == "deployer":
        tx["from"] = deployer

    if is_hardhat:
        unlock = HARDHAT_UNLOCK
        lock = HARDHAT_LOCK
    else:
        unlock = GANACHE_UNLOCK
        lock = GANACHE_LOCK

    web3.provider.make_request(unlock, [tx["from"]])
    txhash = web3.eth.sendTransaction(tx)
    web3.provider.make_request(lock, [tx["from"]])

    rcpt = web3.eth.getTransactionReceipt(txhash)
    if rcpt.status != 1:
        return None

    return rcpt


def load_bytecode(contract_name: str) -> str:
    with open("/home/ctf/compiled.bin", "r") as f:
        compiled = json.load(f)

    return compiled["contracts"][contract_name]["bin"]


def check_pow() -> bool:
    BITS = 24
    resource = "".join(random.choice(string.ascii_lowercase) for i in range(8))
    stamp = input(f"hashcash -mb{BITS} {resource} = ? ")

    if stamp != os.getenv("SKIP_SECRET"):
        if not stamp.startswith("1:"):
            return False
        if not hashcash.check(stamp, resource, BITS):
            return False
    return True


def new_launch_instance_action(
    contract_name: str = "contracts/Setup.sol:Setup", 
    deploy_value: int = 0,
    get_other_txs: Optional[Callable[[str], List[Dict]]] = None,
):
    is_hardhat: bool = False
    with open("/home/ctf/compiled.bin", "r") as f:
        compiled = json.load(f)
        if compiled["contracts"].get("contracts/YieldAggregator.sol:YieldAggregator") is not None:
            is_hardhat = True

    def action() -> int:
        if not check_pow():
            print("bad pow")
            return 1

        headers = {
            "X-Auth-Key": load_auth_key(),
        }

        # edge case
        if is_hardhat:
            headers["Node-Type"] = "hardhat"

        data = requests.post(
            f"{INTERNAL_URL}/new",
            headers=headers,
        ).json()

        if data["ok"] == False:
            print("failed to launch instance! please try again")
            return 1

        uuid = data["uuid"]
        mnemonic = data["mnemonic"]

        provider = Web3.HTTPProvider(
            f"{INTERNAL_URL}/{uuid}",
            request_kwargs={
                "headers": {
                    "X-Auth-Key": load_auth_key(),
                    "Content-Type": "application/json",
                },
            },
        )
        web3 = Web3(provider)

        deployer_addr = Account.create().address

        def send_txs(txs) -> str:
            deployed: Optional[str] = None
            for tx in txs:
                rcpt = send_tx(web3, tx, deployer_addr, is_hardhat)
                if not rcpt:
                    print("internal error while performing setup, please try again")
                    return 1
                if deployed is None and rcpt.contractAddress:
                    deployed = rcpt.contractAddress
            if not deployed:
                print("failed to deploy contract, please try again")
                return 1
            return deployed

        setup_addr = send_txs([
            {
                "from": "0x000000000000000000000000000000000000dEaD",
                "to": "deployer",
                "value": Web3.toWei(10000, "ether"),
            },
            {
                "from": "deployer",
                "value": deploy_value,
                "data": load_bytecode(contract_name),
            },
        ])
        
        if get_other_txs:
            send_txs(get_other_txs(setup_addr))

        with open(f"/tmp/{uuid}", "w") as f:
            f.write(setup_addr)

        player_acct = Account.from_mnemonic(mnemonic)
        print()
        print(f"your private blockchain has been deployed")
        print(f"it will automatically terminate in 30 minutes")
        print(f"here's some useful information")
        print(f"uuid:           {uuid}")
        print(f"rpc endpoint:   {PUBLIC_URL}/{uuid}")
        print(f"private key:    {player_acct.privateKey.hex()}")
        print(f"setup contract: {setup_addr}")
        return 0

    return Action(name="launch new instance", handler=action)


def is_solved_checker(addr: str, web3: Web3) -> bool:
    result = web3.eth.call(
        {
            "to": addr,
            "data": web3.sha3(text="isSolved()")[:4],
        }
    )
    return int(result.hex(), 16) == 1


def new_get_flag_action(
    checker: Callable[[str, Web3], bool] = is_solved_checker,
):
    flag = os.getenv("FLAG", "PCTF{placeholder}")

    def action() -> int:
        uuid = input("uuid? ")

        try:
            uuid = str(UUID(uuid))

            with open(f"/tmp/{uuid}", "r") as f:
                addr = f.read()
        except:
            print("bad uuid")
            return 1

        web3 = Web3(Web3.HTTPProvider(f"{INTERNAL_URL}/{uuid}"))

        if not checker(addr, web3):
            print("are you sure you solved it?")
            return 1

        print(flag)
        return 0

    return Action(name="get flag", handler=action)



def run_launcher(actions: List[Action]):
    for i, action in enumerate(actions):
        print(f"{i+1} - {action.name}")

    action = int(input("action? ")) - 1
    if action < 0 or action >= len(actions):
        print("can you not")
        exit(1)

    exit(actions[action].handler())
