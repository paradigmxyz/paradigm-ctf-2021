pragma solidity 0.8.0;

interface ERC20Like {
    function transfer(address dst, uint256 qty) external returns (bool);

    function transferFrom(
        address src,
        address dst,
        uint256 qty
    ) external returns (bool);

    function balanceOf(address who) external view returns (uint256);

    function approve(address guy, uint256 wad) external returns (bool);
}

interface Protocol {
    function mint(uint256 amount) external;
    function burn(uint256 amount) external;
    function underlying() external view returns (ERC20Like);
    function balanceUnderlying() external view returns (uint256);
    function rate() external view returns (uint256);
}

// accepts multiple tokens and forwards them to banking protocols compliant to an
// interface
contract YieldAggregator {
    address public owner;
    address public harvester;

    mapping (address => uint256) public poolTokens;

    constructor() {
        owner = msg.sender;
    }

    function deposit(Protocol protocol, address[] memory tokens, uint256[] memory amounts) public {
        uint256 balanceBefore = protocol.balanceUnderlying();
        for (uint256 i= 0; i < tokens.length; i++) {
            address token = tokens[i];
            uint256 amount = amounts[i];

            ERC20Like(token).transferFrom(msg.sender, address(this), amount);
            ERC20Like(token).approve(address(protocol), 0);
            ERC20Like(token).approve(address(protocol), amount);
            // reset approval for failed mints
            try protocol.mint(amount) { } catch {
                ERC20Like(token).approve(address(protocol), 0);
            }
        }
        uint256 balanceAfter = protocol.balanceUnderlying();
        uint256 diff = balanceAfter - balanceBefore;
        poolTokens[msg.sender] += diff;
    }

    function withdraw(Protocol protocol, address[] memory tokens, uint256[] memory amounts) public {
        uint256 balanceBefore = protocol.balanceUnderlying();
        for (uint256 i= 0; i < tokens.length; i++) {
            address token = tokens[i];
            uint256 amount = amounts[i];
            protocol.burn(amount);
            ERC20Like(token).transfer(msg.sender, amount);
        }
        uint256 balanceAfter = protocol.balanceUnderlying();

        uint256 diff = balanceBefore - balanceAfter;
        poolTokens[msg.sender] -= diff;
    }
}
