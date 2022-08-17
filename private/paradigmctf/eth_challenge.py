from mp import *

import json
import subprocess
import os
import time

from typing import Tuple

from web3 import Web3
from web3.exceptions import TransactionNotFound
from eth_account import Account

REMOTE_IP = os.getenv("REMOTE_IP")
REMOTE_PORT = os.getenv("REMOTE_PORT")
DEPLOY_ETH = os.getenv("DEPLOY_ETH", "0")

def compile() -> str:
    cwd = os.getcwd()
    parent = os.path.dirname(cwd)
    
    result = subprocess.run(
        ["env", "solc", f"public={parent}/public/contracts/", f"private={parent}/private/", "--combined-json", "bin", "Exploit.sol"],
        capture_output=True,
        env={
            **os.environ,
        },
    )
    if result.returncode:
        raise Exception(result.stderr.decode('utf8'))

    compiled = json.loads(result.stdout)
    return compiled['contracts']['Exploit.sol:Exploit']['bin']


def send_tx(web3, tx):
    txhash = web3.eth.sendTransaction(tx)

    while True:
        try:
            rcpt = web3.eth.getTransactionReceipt(txhash)
            break
        except TransactionNotFound:
            time.sleep(0.1)
            
    if rcpt.status != 1:
        raise Exception("deployment failed")
    return rcpt

def sign_send_tx(web3, account, tx):
    raw = account.sign_transaction(tx)
    txhash = web3.eth.sendRawTransaction(raw.rawTransaction)

    while True:
        try:
            rcpt = web3.eth.getTransactionReceipt(txhash)
            break
        except TransactionNotFound:
            time.sleep(0.1)
    
    if rcpt.status != 1:
        raise Exception("deployment failed")
    return rcpt


def init() -> Tuple[str, Web3, str, str]:
    p = remote(REMOTE_IP, int(REMOTE_PORT))
    
    p >> 'action?' << '1\n'
    p >> '= ?' << 'secret\n'

    p >> 'uuid:'
    uuid = p.recvline().strip().decode('utf8')

    p >> 'rpc endpoint:'
    rpc = p.recvline().strip().decode('utf8')

    p >> 'private key:'
    private = p.recvline().strip().decode('utf8')

    p >> 'setup contract:'
    setup = p.recvline().strip().decode('utf8')

    web3 = Web3(Web3.HTTPProvider(rpc))

    account = Account.from_key(private)

    return uuid, web3, account.address, setup

def solve(web3, code, player, setup):
    send_tx(web3, {
        "from": player,
        "gas": 12_500_000,
        "data": code + (setup[2:]).rjust(64, "0"),
        "value": Web3.toWei(DEPLOY_ETH, "ether"),
    })

def submit(uuid) -> str:
    p = remote(REMOTE_IP, int(REMOTE_PORT))

    p >> 'action?' << '2\n'

    p >> 'uuid?' << uuid << '\n'

    line = p.recvline().strip().decode('utf8')

    if not line.startswith("PCTF"):
        raise Exception(line)

    print("got flag", line)

if __name__ == "__main__":
    exploit_bytecode = compile()

    uuid, web3, address, setup = init()

    solve(web3, exploit_bytecode, address, setup)

    submit(uuid)