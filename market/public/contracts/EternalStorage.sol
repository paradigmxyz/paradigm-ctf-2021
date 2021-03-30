pragma solidity 0.7.0;

interface EternalStorageAPI {
    // mint a new token with the given token id, display name, and owner
    // restricted to: token
    function mint(bytes32 tokenId, bytes32 name, address owner) external;
    
    // update the name of the given token
    // restricted to: token or token owner
    function updateName(bytes32 tokenId, bytes32 name) external;
    // update the owner of the given token
    // restricted to: token or token owner
    function updateOwner(bytes32 tokenId, address newOwner) external;
    // update the approved user of the given token
    // restricted to: token or token owner
    function updateApproval(bytes32 tokenId, address approved) external;
    // update the address which holds the metadata of the given token
    // restricted to: token or token owner
    function updateMetadata(bytes32 tokenId, address metadata) external;
    
    // get the name of the token
    function getName(bytes32 tokenId) external view returns (bytes32);
    // get the owner of the token
    function getOwner(bytes32 tokenId) external view returns (address);
    // get the approved user of the token
    function getApproval(bytes32 tokenId) external view returns (address);
    // get the metadata contract associated with the token
    function getMetadata(bytes32 tokenId) external view returns (address);
    
    // transfers ownership of this storage contract to a new owner
    // restricted to: token
    function transferOwnership(address newOwner) external;
    // accepts ownership of this storage contract
    function acceptOwnership() external;
}

contract EternalStorage {
    constructor(address token) payable {
        assembly {
            sstore(0x00, token)
        }
    }
    
    /*
        Eternal storage implementation. Optimized for gas efficiency so it's written in assembly. Equivalent Solidity:
        
        mapping(bytes32 => TokenInfo) tokens;
        
        struct TokenInfo {
            bytes32 displayName;
            address owner;
            address approved;
            address metadata;
        }
    */
    fallback() external payable {
        assembly {
            function ensureOwner() {
                let owner := sload(0x00)
                
                if iszero(eq(caller(), owner)) {
                    revert(0, 0)
                }
            }
            
            function ensurePendingOwner() {
                let pendingOwner := sload(0x01)
                
                if iszero(eq(caller(), pendingOwner)) {
                    revert(0, 0)
                }
            }
            
            function ensureTokenOwner(tokenId) {
                let owner := sload(0x00)
                let tokenOwner := sload(add(tokenId, 1))
                
                if iszero(or(
                    eq(caller(), owner),
                    eq(caller(), tokenOwner)
                )) {
                    revert(0, 0)
                }
            }
            
            switch shr(224, calldataload(0x00))
                case 0xd8f361ad { // mint(bytes32,bytes32,address)
                    ensureOwner()
                    
                    let tokenId := calldataload(0x04)
                    let name := calldataload(0x24)
                    let owner := and(calldataload(0x44), 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
                    
                    sstore(tokenId, name)
                    sstore(add(tokenId, 1), owner)
                }
                case 0xa9fde064 { // updateName(bytes32,bytes32)
                    let tokenId := calldataload(0x04)
                    let newName := calldataload(0x24)
                    
                    ensureTokenOwner(tokenId)
                    sstore(tokenId, newName)
                }
                case 0x9711a543 { // updateOwner(bytes32,address)
                    let tokenId := calldataload(0x04)
                    let newOwner := and(calldataload(0x24), 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
                    
                    ensureTokenOwner(tokenId)
                    sstore(add(tokenId, 1), newOwner)
                }
                case 0xbdce9bde { // updateApproval(bytes32,address)
                    let tokenId := calldataload(0x04)
                    let newApproval := and(calldataload(0x24), 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
                    
                    ensureTokenOwner(tokenId)
                    sstore(add(tokenId, 2), newApproval)
                }
                case 0x169dbe24 { // updateMetadata(bytes32,address)
                    let tokenId := calldataload(0x04)
                    let newMetadata := and(calldataload(0x24), 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
                    
                    ensureTokenOwner(tokenId)
                    sstore(add(tokenId, 3), newMetadata)
                }
                case 0x54b8d5e3 { // getName(bytes32)
                    let tokenId := calldataload(0x04)
                    let tokenOwner := sload(tokenId)
                    
                    mstore(0x00, tokenOwner)
                    return(0x00, 0x20)
                }
                case 0xdeb931a2 { // getOwner(bytes32)
                    let tokenId := calldataload(0x04)
                    let tokenOwner := sload(add(tokenId, 1))
                    
                    mstore(0x00, tokenOwner)
                    return(0x00, 0x20)
                }
                case 0x1cb9a344 { // getApproval(bytes32)
                    let tokenId := calldataload(0x04)
                    let approved := sload(add(tokenId, 2))
                    
                    mstore(0x00, approved)
                    return(0x00, 0x20)
                }
                case 0xa5961b4c { // getMetadata(bytes32)
                    let tokenId := calldataload(0x04)
                    let tokenMetadata := sload(add(tokenId, 3))
                    
                    mstore(0x00, tokenMetadata)
                    return(0x00, 0x20)
                }
                case 0xf2fde38b { // transferOwnership(address)
                    ensureOwner()
                    
                    let newOwner := and(calldataload(0x04), 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
                    sstore(0x01, newOwner)
                }
                case 0x79ba5097 { // acceptOwnership()
                    ensurePendingOwner()
                    
                    sstore(0x00, sload(0x01))
                    sstore(0x01, 0x00)
                }
                default {
                    revert(0, 0)
                }
        }
    }
}
