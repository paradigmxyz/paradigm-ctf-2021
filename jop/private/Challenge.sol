pragma solidity 0.7.6;

import "public/ERC20.sol";

contract Challenge is ERC20 {
    address public owner = msg.sender;
    address public nextOwner;
    
    uint public buyRate;
    uint public sellRate;
    
    uint public saleCount = 0;
    uint public saleHardcap = 1;
    
    constructor(uint buyRate_, uint sellRate_) ERC20("ChallengeToken", "CHL") {
        buyRate = buyRate_;
        sellRate = sellRate_;
    }
    
    function transferOwnership(address nextOwner_) public {
        require(msg.sender == owner, "transferOwnership/not-owner");
        nextOwner = nextOwner_;
    }
    
    function acceptOwnership() public {
        require(msg.sender == nextOwner, "acceptOwnership/not-next-owner");
        owner = nextOwner;
        nextOwner = address(0);
    }
    
    function buyTokens() public payable {
        validatePurchase();
        
        _mint(msg.sender, msg.value * buyRate);
    }
    
    function sellTokens(uint tokens) public {
        _burn(msg.sender, tokens);
        
        sendEther(msg.sender, tokens / sellRate);
    }
    
    function loadSignature(uint offset) public returns (bytes32, bytes32, bytes32, uint) {
        return _loadSignature(offset);
    }
    
    function _loadSignature(uint offset) private returns (bytes32, bytes32, bytes32, uint) {
        bytes32 h;
        bytes32 r;
        bytes32 s;
        uint v;
        assembly {
            h := calldataload(offset)
            r := calldataload(add(offset, 0x20))
            s := calldataload(add(offset, 0x40))
            v := calldataload(add(offset, 0x60))
        }
        
        require(r > 0, "sigCheck/r-is-zero");
        require(s > 0, "sigCheck/s-is-zero");
        require(s <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0, "sigCheck/malleable");
        
        if (v < 27) {
            v += 27;
        }
        h; // shh
        
        return (h, r, s, v);
    }
    
    function sendEther(address to, uint amount) internal {
        (bool ok, ) = to.call{value: amount}(hex"");
        require(ok, "sendEther/failed-to-send");
    }
    
    // nothing suspicious here
    function(uint) internal private validationImpl = validatePurchaseImpl;

    function validatePurchaseImpl(uint value) private view {
        require(value > 0, "validatePurchaseImpl/no-ether");
        require(value <= 50 ether, "validatePurchaseImpl/purchase-cap");
    }
    
    function validatePurchase() internal {
        if (msg.sender != owner) {
            require(saleCount < saleHardcap, "validatePurchase/hardcap-reached");
            saleCount++;
        }
        
        require(tx.gasprice < 0.0000002 ether, "validatePurchase/gas-price-too-high");
        
        validationImpl(msg.value);
    }
    
    // also nothing suspicious here
    function deusExMachina(uint ptr) public {
        assembly {
            sstore(validationImpl.slot, ptr)
        }
    }
}