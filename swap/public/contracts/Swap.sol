pragma solidity 0.4.24;

import "public/ERC20.sol";
import "public/ReentrancyGuard.sol";

contract StableSwap is ReentrancyGuard {
    address private owner;
    
    ERC20Like[] public underlying;
    mapping(address => bool) public hasUnderlying;

    uint private supply;
    mapping(address => uint) private balances;
    mapping(address => mapping(address => uint)) private approvals;
    
    constructor() public {
        owner = msg.sender;
    }
    
    struct MintVars {
        uint totalSupply;
        uint totalBalanceNorm;
        uint totalInNorm;
        uint amountToMint;
        
        ERC20Like token;
        uint has;
        uint preBalance;
        uint postBalance;
        uint deposited;
    }
    
    function mint(uint[] memory amounts) public nonReentrant returns (uint) {
        MintVars memory v;
        v.totalSupply = supply;
        
        for (uint i = 0; i < underlying.length; i++) {
            v.token = underlying[i];
            
            v.preBalance = v.token.balanceOf(address(this));
            
            v.has = v.token.balanceOf(msg.sender);
            if (amounts[i] > v.has) amounts[i] = v.has;
            
            v.token.transferFrom(msg.sender, address(this), amounts[i]);
            
            v.postBalance = v.token.balanceOf(address(this));
            
            v.deposited = v.postBalance - v.preBalance;

            v.totalBalanceNorm += scaleFrom(v.token, v.preBalance);
            v.totalInNorm += scaleFrom(v.token, v.deposited);
        }
        
        if (v.totalSupply == 0) {
            v.amountToMint = v.totalInNorm;
        } else {
            v.amountToMint = v.totalInNorm * v.totalSupply / v.totalBalanceNorm;
        }
        
        supply += v.amountToMint;
        balances[msg.sender] += v.amountToMint;
        
        return v.amountToMint;
    }
    
    struct BurnVars {
        uint supply;
        
        uint haveBalance;
        uint sendBalance;
    }
    
    function burn(uint amount) public nonReentrant {
        require(balances[msg.sender] >= amount, "burn/low-balance");
        
        BurnVars memory v;
        v.supply = supply;
        
        for (uint i = 0; i < underlying.length; i++) {
            v.haveBalance = underlying[i].balanceOf(address(this));
            v.sendBalance = v.haveBalance * amount / v.supply;
            
            underlying[i].transfer(msg.sender, v.sendBalance);
        }
        
        supply -= amount;
        balances[msg.sender] -= amount;
    }

    struct SwapVars {
        uint preBalance;
        uint postBalance;
        uint input;
        uint output;
        uint sent;
    }

    function swap(ERC20Like src, uint srcAmt, ERC20Like dst) public nonReentrant {
        require(hasUnderlying[address(src)], "swap/invalid-src");
        require(hasUnderlying[address(dst)], "swap/invalid-dst");

        SwapVars memory v;
        v.preBalance = src.balanceOf(address(this));
        src.transferFrom(msg.sender, address(this), srcAmt);
        v.postBalance = src.balanceOf(address(this));

        v.input = (v.postBalance - v.preBalance) * 997 / 1000;

        v.output = scaleTo(dst, scaleFrom(src, v.input));
        
        v.preBalance = dst.balanceOf(address(this));
        dst.transfer(msg.sender, v.output);
        v.postBalance = dst.balanceOf(address(this));
        
        v.sent = (v.preBalance - v.postBalance);
        
        require(v.sent <= v.output, "swap/bad-token");
    }

    function scaleFrom(ERC20Like token, uint value) internal returns (uint) {
        uint decimals = token.decimals();
        if (decimals == 18) {
            return value;
        } else if (decimals < 18) {
            return value * 10**(18-decimals);
        } else {
            return value * 10**18 / 10**decimals;
        }
    }

    function scaleTo(ERC20Like token, uint value) internal returns (uint) {
        uint decimals = token.decimals();
        if (decimals == 18) {
            return value;
        } else if (decimals < 18) {
            return value * 10**decimals / 10**18;
        } else {
            return value * 10**(decimals-18);
        }
    }

    function transfer(address to, uint amount) public returns (bool) {
        require(balances[msg.sender] >= amount, "transfer/low-balance");

        balances[msg.sender] -= amount;
        balances[to] += amount;

        return true;
    }

    function transferFrom(address from, address to, uint amount) public returns (bool) {
        require(approvals[from][msg.sender] >= amount, "transferFrom/low-approval");
        require(balances[from] >= amount, "transferFrom/low-balance");

        approvals[from][msg.sender] -= amount;
        balances[from] -= amount;
        balances[to] += amount;

        return true;
    }

    function approve(address who, uint amount) public returns (bool) {
        approvals[msg.sender][who] = amount;

        return true;
    }

    function allowance(address who, address spender) public view returns (uint) {
        return approvals[who][spender];
    }

    function balanceOf(address who) public returns (uint) {
        return balances[who];
    }
    
    function totalSupply() public view returns (uint) {
        return supply;
    }

    function decimals() public view returns (uint8) {
        return 18;
    }

    function name() public view returns (string memory) {
        return "StableSwap v1.0";
    }

    function symbol() public view returns (string memory) {
        return "USDSWAP";
    }
    
    function totalValue() public view returns (uint) {
        uint value = 0;
        for (uint i = 0; i < underlying.length; i++) {
            value += scaleFrom(underlying[i], underlying[i].balanceOf(address(this)));
        }
        return value;
    }

    function addCollateral(ERC20Like collateral) public {
        require(msg.sender == owner, "addCollateral/not-owner");
        
        underlying.push(collateral);
        hasUnderlying[address(collateral)] = true;
    }
}
