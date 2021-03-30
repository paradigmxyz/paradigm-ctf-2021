pragma solidity 0.6.12;

import "./FiatTokenV2.sol";

/**
 * @title FiatToken V3
 * @notice ERC20 Token backed by fiat reserves, version 3
 */
contract FiatTokenV3 is FiatTokenV2 {
    // ensure we start on a new storage slot just in case
    uint private _gap;

    bool internal _initializedV3;

    mapping(address => mapping(address => uint256)) private _loans;

    /**
     * @notice Initialize V3 contract
     * @dev When upgrading to V3, this function must also be invoked by using
     * upgradeToAndCall instead of upgradeTo, or by calling both from a contract
     * in a single transaction.
     */
    function initializeV3() external {
        require(
            !_initializedV3,
            "FiatTokenV3: contract is already initialized"
        );
        DOMAIN_SEPARATOR = EIP712.makeDomainSeparator(name, "3");
        _initializedV3 = true;
    }

    /**
     * @notice Lends some tokens to the specified address
     * @param to        Recipient's address
     * @param amount    Loan amount
     * @return True if successful
     */
    function lend(address to, uint amount)
        external
        whenNotPaused
        notBlacklisted(msg.sender)
        notBlacklisted(to)
        returns (bool)
    {
        _loans[msg.sender][to] = _loans[msg.sender][to].add(amount);

        _transfer(msg.sender, to, amount);
        return true;
    }

    /**
     * @notice Reclaims previously lent tokens
     * @param from      The account to which tokens were lent
     * @param amount    Reclaim amount
     * @return True if successful
     */
    function reclaim(address from, uint amount)
        external
        whenNotPaused
        notBlacklisted(msg.sender)
        notBlacklisted(from)
        returns (bool)
    {
        _loans[msg.sender][from] = _loans[msg.sender][from].sub(amount, "FiatTokenV3: decreased loans below zero");

        _transfer(from, msg.sender, amount);
        return true;
    }
}
