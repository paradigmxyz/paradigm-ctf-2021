pragma solidity 0.4.16;

import "./Guard.sol";
import "./Vault.sol";

contract SingleOwnerGuard is Guard {
    bytes32 public constant id = "single-owner";
    
    bool private initialized;
    Vault private vault;
    
    string[] public publicOps;
    
    // initialize the proxy instance for the given vault
    function initialize(Vault vault_) external {
        require(!initialized);
        
        vault = vault_;
        initialized = true;
    }
    
    // clean up the proxy instance. must be the vault owner
    function cleanup() external {
        require(msg.sender == address(vault));
        require(vault.guard() == this);
        
        selfdestruct(owner());
    }
    
    // check if the sender is the owner, or if the op is public
    function isAllowed(address who, string op) external view returns (uint8, uint8) {
        if (who == owner()) return (NO_ERROR, 1);
        
        for (uint i = 0; i < publicOps.length; i++) {
            if (keccak256(publicOps[i]) == keccak256(op)) {
                return (NO_ERROR, 2);
            }
        }
        
        return (PERMISSION_DENIED, 1);
    }
    
    // add a new public op. must be owner
    function addPublicOperation(string op) external {
        require(msg.sender == owner());
        
        publicOps.push(op);
    }
    
    // get the owner of the guard (who is also the owner of the vault)
    function owner() public view returns (address) {
        return vault.owner();
    }
}