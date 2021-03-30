pragma solidity 0.7.0;

import "./EternalStorage.sol";

contract CryptoCollectibles {
    address public owner;
    EternalStorageAPI public eternalStorage;
    
    mapping(address => bool) public minters;
    uint public tokenIdSalt;
    
    constructor() {
        owner = msg.sender;
        minters[owner] = true;
    }
    
    // set whether the given address can mint new collectibles
    function setMinter(address newMinter, bool isMinter) external {
        require(msg.sender == owner, "setMinter/not-owner");
        
        minters[newMinter] = isMinter;
    }
    
    // set the storage contract to use
    function setEternalStorage(EternalStorageAPI eternalStorage_) external {
        require(msg.sender == owner, "setEternalStorage/not-owner");
        
        eternalStorage = eternalStorage_;
        eternalStorage.acceptOwnership();
    }
    
    // mint a new collectible. must be a minter
    function mint(address tokenOwner) external returns (bytes32) {
        require(minters[msg.sender], "mint/not-minter");
        
        bytes32 tokenId = keccak256(abi.encodePacked(address(this), tokenIdSalt++));
        eternalStorage.mint(tokenId, "My First Collectible", tokenOwner);
        return tokenId;
    }
    
    // transfer the Collectible to the new user
    function transfer(bytes32 tokenId, address to) external {
        require(msg.sender == eternalStorage.getOwner(tokenId), "transfer/not-owner");
        
        eternalStorage.updateOwner(tokenId, to);
        eternalStorage.updateApproval(tokenId, address(0x00));
    }
    
    // approve the user to transfer the token
    function approve(bytes32 tokenId, address authorized) external {
        require(msg.sender == eternalStorage.getOwner(tokenId), "approve/not-owner");
        
        eternalStorage.updateApproval(tokenId, authorized);
    }
    
    // transfer the token from one user to another. must be approved
    function transferFrom(bytes32 tokenId, address from, address to) external {
        require(from == eternalStorage.getOwner(tokenId), "transferFrom/not-owner");
        require(msg.sender == eternalStorage.getApproval(tokenId), "transferFrom/not-approved");
        
        eternalStorage.updateOwner(tokenId, to);
        eternalStorage.updateApproval(tokenId, address(0x00));
    }
    
    // get all the info associated with the token
    function getTokenInfo(bytes32 tokenId) external view returns (bytes32, address, address, address) {
        return (
            eternalStorage.getName(tokenId),
            eternalStorage.getOwner(tokenId),
            eternalStorage.getApproval(tokenId),
            eternalStorage.getMetadata(tokenId)
        );
    }
    
    // fetch the underlying metadata associated with a collectible
    function getTokenMetadata(bytes32 tokenId) external view returns (bytes memory) {
        address metadata = eternalStorage.getMetadata(tokenId);
        if (metadata == address(0x00)) {
            return new bytes(0);
        }
        
        bytes memory data;
        assembly {
            data := mload(0x40)
            mstore(data, extcodesize(metadata))
            extcodecopy(metadata, add(data, 0x20), 0, mload(data))
        }
        return data;
    }
}

contract CryptoCollectiblesMarket {
    address payable public owner;
    CryptoCollectibles public cryptoCollectibles;
    
    mapping(bytes32 => uint) tokenPrices;
    uint public minMintPrice;
    uint public mintFeeBps;
    uint public feeCollected;
    
    constructor(CryptoCollectibles cryptoCollectibles_, uint minMintPrice_, uint mintFeeBps_) {
        owner = msg.sender;
        cryptoCollectibles = cryptoCollectibles_;
        minMintPrice = minMintPrice_;
        mintFeeBps = mintFeeBps_;
    }
    
    // buy a collectible from the market for the listed price
    function buyCollectible(bytes32 tokenId) public payable {
        require(tokenPrices[tokenId] > 0, "buyCollectible/not-listed");
        
        (, address tokenOwner, , ) = cryptoCollectibles.getTokenInfo(tokenId);
        require(tokenOwner == address(this), "buyCollectible/already-sold");
        
        require(msg.value == tokenPrices[tokenId], "buyCollectible/bad-value");
        
        cryptoCollectibles.transfer(tokenId, msg.sender);
    }
    
    // sell a collectible back to the market for the listed price
    function sellCollectible(bytes32 tokenId) public payable {
        require(tokenPrices[tokenId] > 0, "sellCollectible/not-listed");
        
        (, address tokenOwner, address approved, ) = cryptoCollectibles.getTokenInfo(tokenId);
        require(msg.sender == tokenOwner, "sellCollectible/not-owner");
        require(approved == address(this), "sellCollectible/not-approved");
        
        cryptoCollectibles.transferFrom(tokenId, msg.sender, address(this));
        
        msg.sender.transfer(tokenPrices[tokenId]);
    }
    
    // mint a new collectible for yourself. must pay the minting fee!
    function mintCollectible() public payable returns (bytes32) {
        return mintCollectibleFor(msg.sender);
    }
    
    // mint a new collectible for someone else. must pay the minting fee!
    function mintCollectibleFor(address who) public payable returns (bytes32) {
        uint sentValue = msg.value;
        uint mintPrice = sentValue * 10000 / (10000 + mintFeeBps);
        
        require(mintPrice >= minMintPrice, "mintCollectible/bad-value");
        
        bytes32 tokenId = cryptoCollectibles.mint(who);
        tokenPrices[tokenId] = mintPrice;
        feeCollected += sentValue - mintPrice;
        return tokenId;
    }
    
    // owner can withdraw minting fees
    function withdrawFee() public {
        require(msg.sender == owner, "withdrawFee/not-owner");
        
        owner.transfer(feeCollected);
        feeCollected = 0;
    }
}
