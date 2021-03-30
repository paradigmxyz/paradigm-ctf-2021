pragma solidity 0.4.16;

import "./GuardConstants.sol";
import "./GuardRegistry.sol";
import "./Guard.sol";

contract ERC20Like {
    function transfer(address dst, uint qty) public returns (bool);
    function transferFrom(address src, address dst, uint qty) public returns (bool);
}

contract EIP1167Factory {
    // create eip-1167 clone
    function createClone(address target) internal returns (address result) {
        bytes20 targetBytes = bytes20(target);
        assembly {
            let clone := mload(0x40)
            mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(clone, 0x14), targetBytes)
            mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            result := create(0, clone, 0x37)
        }
    }
}

contract Vault is GuardConstants, EIP1167Factory {
    address public owner;
    address public pendingOwner;
    
    GuardRegistry public registry;
    
    Guard public guard;
    
    mapping(address => mapping(address => uint)) public balances;
    
    function Vault(GuardRegistry registry_) public {
        owner = msg.sender;
        registry = registry_;
        
        createGuard(registry.defaultImplementation());
    }
    
    // create new guard instance
    function createGuard(bytes32 implementation) private returns (Guard) {
        address impl = registry.implementations(implementation);
        require(impl != address(0x00));
        
        if (address(guard) != address(0x00)) {
            guard.cleanup();
        }
        
        guard = Guard(createClone(impl));
        guard.initialize(this);
        return guard;
    }
    
    // check access
    function checkAccess(string memory op) private returns (bool) {
        uint8 error;
        (error, ) = guard.isAllowed(msg.sender, op);
        
        return error == NO_ERROR;
    }
    
    // update the guard implementation
    function updateGuard(bytes32 impl) public returns (Guard) {
        require(checkAccess("updateGuard"));
        
        return createGuard(impl);
    }
    
    // deposit tokens
    function deposit(ERC20Like tok, uint amnt) public {
        require(checkAccess("deposit"));
        
        require(tok.transferFrom(msg.sender, address(this), amnt));
        
        balances[msg.sender][address(tok)] += amnt;
    }
    
    // withdraw tokens
    function withdraw(ERC20Like tok, uint amnt) public {
        require(checkAccess("withdraw"));
        
        require(balances[msg.sender][address(tok)] >= amnt);
        
        tok.transfer(msg.sender, amnt);
        
        balances[msg.sender][address(tok)] -= amnt;
    }
    
    // rescue stuck tokens
    function emergencyCall(address target, bytes memory data) public {
        require(checkAccess("emergencyCall"));
        
        require(target.delegatecall(data));
    }
    
    // transfer ownership to a new address
    function transferOwnership(address newOwner) public {
        require(msg.sender == owner);
        
        pendingOwner = newOwner;
    }
    
    // accept the ownership transfer
    function acceptOwnership() public {
        require(msg.sender == pendingOwner);
        
        owner = pendingOwner;
        pendingOwner = address(0x00);
    }
}
