// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "erc1363-payable-token/contracts/token/ERC1363/ERC1363.sol";
import "erc1363-payable-token/contracts/token/ERC1363/IERC1363Receiver.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "openzeppelin-contracts/contracts/utils/Address.sol";
import "prb-math/contracts/PRBMathUD60x18.sol";

/**
 * @title ERC1363 with Bonding Curve
 * @author Josh Guha
 * @dev Accepts ETH as the reserve currency
 */

contract ERC20BondingCurve is ERC1363, IERC1363Receiver {
    using PRBMathUD60x18 for uint256;
    using Address for address;

    uint256 private constant PRICE_COEFFICIENT = 5;

    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}

    /**
     * @dev Function to sell (mint) new tokens via the bonding mechanism
     * @dev Accepts ETH as reserve currency
     * @param data Additional data with no specified format
     */
    function buyTokens(bytes memory data) external payable returns (bool) {
        /*
            x_1 = sqrt((2V_in / m) + x_0^2)

            where x_1 = total supply after
                  x_0 = total supply before
                  V_in = msg.value
                  m = price coefficient
         */

        uint256 initialSupply = totalSupply();
        uint256 mintAmount = ((2 * msg.value).div(PRICE_COEFFICIENT) +
            initialSupply.pow(2)).sqrt();

        _mint(msg.sender, mintAmount, data);
        return true;
    }

    /**
     * @dev Function to allow token receipt and buy back via the bonding mechanism
     * @dev Implements IERC1363Receiver
     * @dev Returns ETH to spender
     * @param spender Spender of token
     * @param sender Transction sender
     * @param amount Amount of tokens received (and therefore bought back and burnt)
     * @param data Additional data with no specified format
     */

    function onTransferReceived(
        address spender,
        address sender,
        uint256 amount,
        bytes calldata data
    ) external returns (bytes4) {
        /*
            V_out = m (x_0^2 - x_1^2) / 2

            where x_1 = total supply after
                  x_0 = total supply before
                  V_out = redeem amount
                  m = price coefficient
         */

        uint256 initialSupply = totalSupply();
        uint256 finalSupply = initialSupply - amount;
        uint256 returnETH = PRICE_COEFFICIENT
            .mul(initialSupply.pow(2) - finalSupply.pow(2))
            .div(2);

        _burn(spender, amount);

        (bool sent, ) = spender.call{value: returnETH}("");
        require(sent, "Failed to send Ether");

        return IERC1363Receiver.onTransferReceived.selector;
    }

    /**
     * @dev Function to override ERC20 mint with transfer checks
     * @param account Address to mint tokens to
     * @param amount Amount of tokens to buy back
     * @param data Additional data with no specified format
     */

    function _mint(
        address account,
        uint256 amount,
        bytes memory data
    ) internal {
        super._mint(account, amount);
        if (account.isContract()) {
            require(
                _checkOnTransferReceived(address(0), account, amount, data),
                "ERC1363: receiver returned wrong data"
            );
        }
    }
}
