from mp import *

from ecdsa import ecdsa
from ecdsa.numbertheory import inverse_mod
import sha3
import binascii

def hash_message(msg: str) -> int:
    """
    hash the message using keccak256, truncate if necessary
    """
    k = sha3.keccak_256()
    k.update(msg.encode('utf8'))
    d = k.digest()
    n = int(binascii.hexlify(d), 16)
    olen = ecdsa.generator_secp256k1.order().bit_length() or 1
    dlen = len(d)
    n >>= max(0, dlen - olen)
    return n

REMOTE_IP = os.getenv("REMOTE_IP")
REMOTE_PORT = os.getenv("REMOTE_PORT")

p = remote(REMOTE_IP, int(REMOTE_PORT))

# p = process('python3', 'chal.py')

p >> 'message? ' << 'message1\n' >> 'r='
r1 = int(p.recvline(), 16)
p >> 's='
s1 = int(p.recvline(), 16)

p >> 'message? ' << 'message2\n' >> 'r='
r2 = int(p.recvline(), 16)
p >> 's='
s2 = int(p.recvline(), 16)

p << 'a\nb\n' >> "test="

test = int(p.recvline(), 16)
print("test", hex(test))
print("s1", hex(s1))
print("s2", hex(s2))

assert r1 == r2

h1 = hash_message("message1")
h2 = hash_message("message2")

for v in (
    s1 - s2,
    s1 + s2,
    -s1 - s2,
    -s1 + s2
):
    k = inverse_mod(v, ecdsa.generator_secp256k1.order()) * (h1 - h2) % ecdsa.generator_secp256k1.order()
    d = inverse_mod(r1, ecdsa.generator_secp256k1.order()) * (k*s1 - h1) % ecdsa.generator_secp256k1.order()
    
    g = ecdsa.generator_secp256k1
    pub = ecdsa.Public_key(g, g * d)
    priv = ecdsa.Private_key(pub, d)
    if pub.verifies(h1, ecdsa.Signature(r1, s1)):
        break

sig = priv.sign(test, 1)
p >> 'r? ' << hex(sig.r) << '\n'
p >> 's? ' << hex(sig.s) << '\n'

flag = p.recvline().decode('utf8')
print("got flag", str(flag))
