pragma solidity 0.8.0;

interface IUniswapV2Pair {
    function mint(address to) external returns (uint liquidity);
    function getReserves() external view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
}

interface ERC20Like {
    function transfer(address dst, uint qty) external returns (bool);
    function transferFrom(address src, address dst, uint qty) external returns (bool);
    function approve(address dst, uint qty) external returns (bool);
    
    function balanceOf(address who) external view returns (uint);
}

interface WETH9 is ERC20Like {
    function deposit() external payable;
}

// a simple overcollateralized loan bank which accepts WETH as collateral and a
// token for borrowing. 0% APRs
contract Broker {
    IUniswapV2Pair public pair;
    WETH9 public constant weth = WETH9(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    ERC20Like public token;


    mapping(address => uint256) public deposited;
    mapping(address => uint256) public debt;

    constructor (IUniswapV2Pair _pair, ERC20Like _token) {
        pair = _pair;
        token = _token;
    }

    function rate() public view returns (uint256) {
        (uint112 _reserve0, uint112 _reserve1,) = pair.getReserves();
        uint256 _rate = uint256(_reserve0 / _reserve1);
        return _rate;
    }

    function safeDebt(address user) public view returns (uint256) {
        return deposited[user] * rate() * 2 / 3;
    }

    // borrow some tokens
    function borrow(uint256 amount) public {
        debt[msg.sender] += amount;
        require(safeDebt(msg.sender) >= debt[msg.sender], "err: undercollateralized");
        token.transfer(msg.sender, amount);
    }

    // repay your loan
    function repay(uint256 amount) public {
        debt[msg.sender] -= amount;
        token.transferFrom(msg.sender, address(this), amount);
    }

    // repay a user's loan and get back their collateral. no discounts.
    function liquidate(address user, uint256 amount) public returns (uint256) {
        require(safeDebt(user) <= debt[user], "err: overcollateralized");
        debt[user] -= amount;
        token.transferFrom(msg.sender, address(this), amount);
        uint256 collateralValueRepaid = amount / rate();
        weth.transfer(msg.sender, collateralValueRepaid);
        return collateralValueRepaid;
    }

    // top up your collateral
    function deposit(uint256 amount) public {
        deposited[msg.sender] += amount;
        weth.transferFrom(msg.sender, address(this), amount);
    }

    // remove collateral
    function withdraw(uint256 amount) public {
        deposited[msg.sender] -= amount;
        require(safeDebt(msg.sender) >= debt[msg.sender], "err: undercollateralized");

        weth.transfer(msg.sender, amount);
    }
}
