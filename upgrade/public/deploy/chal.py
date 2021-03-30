import eth_sandbox
from web3 import Web3

def generate_txs(contract_addr: str):
    return [
        {
            "from": "0x807a96288A1A408dBC13DE2b1d087d10356395d2",
            "to": "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48",
            "data": "0x8f283970000000000000000000000000" + contract_addr[2:],
        },
        {
            "gas": 10000000,
            "gasPrice": 0,
            "from": "deployer",
            "to": contract_addr,
            "data": Web3.sha3(text="upgrade()")[:10],
        },
    ]

eth_sandbox.run_launcher([
    eth_sandbox.new_launch_instance_action(get_other_txs=generate_txs),
    eth_sandbox.new_get_flag_action()
])
