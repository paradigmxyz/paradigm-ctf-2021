pragma solidity 0.4.24;

contract Stage {
    Stage public next;
    
    constructor(Stage next_) public {
        next = next_;
    }
    
    function getSelector() public view returns (bytes4);
    
    modifier _() {
        _;
        
        assembly {
            let next := sload(next_slot)
            if iszero(next) {
                return(0, 0)
            }
            
            mstore(0x00, 0x034899bc00000000000000000000000000000000000000000000000000000000)
            pop(call(gas(), next, 0, 0, 0x04, 0x00, 0x04))
            calldatacopy(0x04, 0x04, sub(calldatasize(), 0x04))
            switch call(gas(), next, 0, 0, calldatasize(), 0, 0)
                case 0 {
                    returndatacopy(0x00, 0x00, returndatasize())
                    revert(0x00, returndatasize())
                }
                case 1 {
                    returndatacopy(0x00, 0x00, returndatasize())
                    return(0x00, returndatasize())
                }
        }
    }
}

contract Entrypoint is Stage {
    constructor() public Stage(new Stage1()) {} function getSelector() public view returns (bytes4) { return this.solve.selector; }
    
    bool public solved;
    
    function solve(bytes4 guess) public _ {
        require(guess == bytes4(blockhash(block.number - 1)), "do you feel lucky?");
        
        solved = true;
    }
}

contract Stage1 is Stage {
    constructor() public Stage(new Stage2()) {} function getSelector() public view returns (bytes4) { return this.solve.selector; }
    
    function solve(uint8 v, bytes32 r, bytes32 s) public _ {
        require(ecrecover(keccak256("stage1"), v, r, s) == 0x7E5F4552091A69125d5DfCb7b8C2659029395Bdf, "who are you?");
    }
}

contract Stage2 is Stage {
    constructor() public Stage(new Stage3()) {} function getSelector() public view returns (bytes4) { return this.solve.selector; }
    
    function solve(uint16 a, uint16 b) public _ {
        require(a > 0 && b > 0 && a + b < a, "something doesn't add up");
    }
}

contract Stage3 is Stage {
    constructor() public Stage(new Stage4()) {} function getSelector() public view returns (bytes4) { return this.solve.selector; }
    
    function solve(uint idx, uint[4] memory keys, uint[4] memory lock) public _ {
        require(keys[idx % 4] == lock[idx % 4], "key did not fit lock");
        
        for (uint i = 0; i < keys.length - 1; i++) {
            require(keys[i] < keys[i + 1], "out of order");
        }
        
        for (uint j = 0; j < keys.length; j++) {
            require((keys[j] - lock[j]) % 2 == 0, "this is a bit odd");
        }
    }
}

contract Stage4 is Stage {
    constructor() public Stage(new Stage5()) {} function getSelector() public view returns (bytes4) { return this.solve.selector; }
    
    function solve(bytes32[6] choices, uint choice) public _ {
        require(choices[choice % 6] == keccak256(abi.encodePacked("choose")), "wrong choice!");
    }
}

contract Stage5 is Stage {
    constructor() public Stage(Stage(0x00)) {} function getSelector() public view returns (bytes4) { return this.solve.selector; }
    
    function solve() public _ {
        require(msg.data.length < 256, "a little too long");
    }
}
