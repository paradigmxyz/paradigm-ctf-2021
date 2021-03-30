from pyevmasm import disassemble_all, DEFAULT_FORK
import binascii

# solc --yul --yul-dialect evm impl.yul | grep Binary -A1

def reverseHex(b):
    return "".join(list(reversed([b[i:i+2] for i in range(0, len(b), 2)])))

# straight from the compiler
bytecode = "3d36471c4736035b8183108382033560f81c843560f81c1416156026575b47830192506007565b8183143452602034f3"
print("orig", len(bytecode)//2)

# palindrome it
bytecode = bytecode + reverseHex(bytecode)[2:]
print("palindrome", len(bytecode)//2)

def printb(bytecode):
    insns = list(disassemble_all(binascii.unhexlify(bytecode), fork=DEFAULT_FORK))
    for i in insns:
        print("%08x: %s" % (i.pc, str(i)))

printb(bytecode)

print(bytecode)
print(bytecode == reverseHex(bytecode))