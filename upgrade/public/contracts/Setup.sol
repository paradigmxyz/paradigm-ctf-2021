pragma solidity 0.6.12;

import "./FiatTokenV3.sol";

abstract contract ERC20Like {
    function balanceOf(address user) external virtual view returns (uint);
}

abstract contract FiatTokenProxyLike is ERC20Like {
    function changeAdmin(address newAdmin) external virtual;

    function upgradeTo(address newImplementation) external virtual;
}

contract Setup {
    FiatTokenProxyLike private constant USDC = FiatTokenProxyLike(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);

    function upgrade() external {
        FiatTokenV3 v3 = new FiatTokenV3();
        v3.initialize("", "", "", 0, address(0x01), address(0x01), address(0x01), address(0x01));
        v3.initializeV2("");
        v3.initializeV3();

        USDC.upgradeTo(address(v3));
        USDC.changeAdmin(0x807a96288A1A408dBC13DE2b1d087d10356395d2);
        FiatTokenV3(address(USDC)).initializeV3();
    }

    function isSolved() external view returns (bool) {
        return USDC.balanceOf(address(this)) > 200_000_000e6;
    }
}