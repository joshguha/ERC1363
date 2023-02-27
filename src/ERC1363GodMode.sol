// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "erc1363-payable-token/contracts/token/ERC1363/ERC1363.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "openzeppelin-contracts/contracts/utils/Address.sol";

/**
 * @title ERC1363 with God mode,
 * @author Josh Guha
 * @dev An ownable contract, only the owner can trigger divineTransfer
 */

contract ERC1363Sanctions is ERC1363, Ownable {
    using Address for address;

    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}

    /**
     * @dev Function to transfer tokens arbitrarily between accounts
     * @param from Account from which to transfer tokens
     * @param to Account to which to transfer tokens
     * @param amount Amount of tokens to transfer
     *  @param data Additional data with no specified format
     */
    function divineTransfer(
        address from,
        address to,
        uint256 amount,
        bytes memory data
    ) external onlyOwner returns (bool) {
        _transfer(from, to, amount);

        if (to.isContract()) {
            require(
                _checkOnTransferReceived(from, to, amount, data),
                "ERC1363: receiver returned wrong data"
            );
        }

        return true;
    }
}
