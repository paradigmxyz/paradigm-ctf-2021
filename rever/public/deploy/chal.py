import eth_sandbox
from web3 import Web3
from eth_abi import encode_single
import random
import string

def random_string(N: int) -> str:
    return ''.join(random.choice(string.ascii_uppercase + string.digits) for _ in range(N))

def checker(addr: str, web3: Web3) -> bool:
    testcases = {
        "": True,
        "a": True,
        "ab": False,
        "aba": True,
        "paradigm": False,
        "tattarrattat": True,
    }

    for i in range(10):
        if i % 2 == 0:
            if random.random() > 0.5:
                str = random_string(63)
                testcases[str + random_string(1) + ''.join(reversed(list(str)))] = True
            else:
                str = random_string(64)
                testcases[str + ''.join(reversed(list(str)))] = True
        else:
            testcases[random_string(128)] = False

    for k, v in testcases.items():
        data = web3.sha3(text="test(string)")[:4] + encode_single('uint256', 32) + encode_single('string', k)
        result = web3.eth.call(
            {
                "to": addr,
                "data": data,
            }
        )
        if int(result.hex(), 16) != v:
            return False
    
    return True

eth_sandbox.run_launcher([
    eth_sandbox.new_launch_instance_action(deploy_value=Web3.toWei(0, 'ether')),
    eth_sandbox.new_get_flag_action(checker)
])
