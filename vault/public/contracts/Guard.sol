pragma solidity 0.4.16;

import "./GuardConstants.sol";
import "./Vault.sol";

contract Guard is GuardConstants {
    // initialize the proxied guard for the given vault
    function initialize(Vault owner) external;
    
    // cleanup the proxied guard
    function cleanup() external;
    
    // Check if access is permited for the given user and operation.
    // Returns a result code and a guard-specific code
    function isAllowed(address who, string op) external view returns (uint8 res, uint8 code);
}

contract GuardIdGetter {
    // get the id of the guard
    function id() public view returns (bytes32);
}
