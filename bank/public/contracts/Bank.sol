pragma solidity 0.4.24;

contract ERC20Like {
    function transfer(address dst, uint qty) public returns (bool);
    function transferFrom(address src, address dst, uint qty) public returns (bool);
    function approve(address dst, uint qty) public returns (bool);
    
    function balanceOf(address who) public view returns (uint);
}

contract Bank {
    address public owner;
    address public pendingOwner;
    
    struct Account {
        string accountName;
        uint uniqueTokens;
        mapping(address => uint) balances;
    }
    
    mapping(address => Account[]) accounts;
    
    constructor() public {
        owner = msg.sender;
    }
    
    function depositToken(uint accountId, address token, uint amount) external {
        require(accountId <= accounts[msg.sender].length, "depositToken/bad-account");
        
        // open a new account for the user if necessary
        if (accountId == accounts[msg.sender].length) {
            accounts[msg.sender].length++;
        }
        
        Account storage account = accounts[msg.sender][accountId];
        uint oldBalance = account.balances[token];
        
        // check the user has enough balance and no overflows will occur
        require(oldBalance + amount >= oldBalance, "depositToken/overflow");
        require(ERC20Like(token).balanceOf(msg.sender) >= amount, "depositToken/low-sender-balance");
        
        // increment counter for unique tokens if necessary
        if (oldBalance == 0) {
            account.uniqueTokens++;
        }
        
        // update the balance
        account.balances[token] += amount;
        
        // transfer the tokens in
        uint beforeBalance = ERC20Like(token).balanceOf(address(this));
        require(ERC20Like(token).transferFrom(msg.sender, address(this), amount), "depositToken/transfer-failed");
        uint afterBalance = ERC20Like(token).balanceOf(address(this));
        require(afterBalance - beforeBalance == amount, "depositToken/fee-token");
    }
    
    function withdrawToken(uint accountId, address token, uint amount) external {
        require(accountId < accounts[msg.sender].length, "withdrawToken/bad-account");
        
        Account storage account = accounts[msg.sender][accountId];
        uint lastAccount = accounts[msg.sender].length - 1;
        uint oldBalance = account.balances[token];
        
        // check the user can actually withdraw the amount they want and we have enough balance
        require(oldBalance >= amount, "withdrawToken/underflow");
        require(ERC20Like(token).balanceOf(address(this)) >= amount, "withdrawToken/low-sender-balance");
        
        // update the balance
        account.balances[token] -= amount;
        
        // if the user has emptied their balance, decrement the number of unique tokens
        if (account.balances[token] == 0) {
            account.uniqueTokens--;
            
            // if the user is withdrawing everything from their last account, close it
            // we can't close accounts in the middle of the array because we can't
            // clone the balances mapping, so the user would lose all their balance
            if (account.uniqueTokens == 0 && accountId == lastAccount) {
                accounts[msg.sender].length--;
            }
        }
        
        // transfer the tokens out
        uint beforeBalance = ERC20Like(token).balanceOf(msg.sender);
        require(ERC20Like(token).transfer(msg.sender, amount), "withdrawToken/transfer-failed");
        uint afterBalance = ERC20Like(token).balanceOf(msg.sender);
        require(afterBalance - beforeBalance == amount, "withdrawToken/fee-token");
    }
    
    // set the display name of the account
    function setAccountName(uint accountId, string name) external {
        require(accountId < accounts[msg.sender].length, "setAccountName/invalid-account");
        
        accounts[msg.sender][accountId].accountName = name;
    }
    
    // close the last account if empty - we need this in case we couldn't automatically close
    // the account during withdrawal
    function closeLastAccount() external {
        // make sure the user has an account
        require(accounts[msg.sender].length > 0, "closeLastAccount/no-accounts");
        
        // make sure the last account is empty
        uint lastAccount = accounts[msg.sender].length - 1;
        require(accounts[msg.sender][lastAccount].uniqueTokens == 0, "closeLastAccount/non-empty");
        
        // close the account
        accounts[msg.sender].length--;
    }
    
    // get info about the account
    function getAccountInfo(uint accountId) public view returns (string, uint) {
        require(accountId < accounts[msg.sender].length, "getAccountInfo/invalid-account");
        
        return (
            accounts[msg.sender][accountId].accountName,
            accounts[msg.sender][accountId].uniqueTokens
        );
    }
    
    // get the balance of a token
    function getAccountBalance(uint accountId, address token) public view returns (uint) {
        require(accountId < accounts[msg.sender].length, "getAccountBalance/invalid-account");
        
        return accounts[msg.sender][accountId].balances[token];
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