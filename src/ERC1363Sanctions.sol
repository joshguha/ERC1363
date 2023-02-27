// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "erc1363-payable-token/contracts/token/ERC1363/ERC1363.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";

/**
 * @title ERC1363 with sanctions which prevent transfer to or from banned accounts,
 * @author Josh Guha
 */

contract ERC1363Sanctions is ERC1363, Ownable {
    mapping(address => bool) private banList;

    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}

    /**
     * @dev Function to check if account is banned
     * @param account Account to check on ban list
     */
    function isBanned(address account) public view returns (bool) {
        return banList[account];
    }

    /**
     * @dev Function to add account to ban list
     * @param account Account to add to ban list
     */
    function ban(address account) external onlyOwner {
        require(account != address(0), "Cannot ban zero address");
        banList[account] = true;
    }

    /**
     * @dev Function to remove account from ban list
     * @param account Account to remove from ban list
     */
    function unban(address account) external onlyOwner {
        require(account != address(0), "Cannot unban zero address");
        banList[account] = false;
    }

    /**
     * @dev Override ERC20 _beforeTokenTransfer to block transfer to or from banned accounts
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 // amount
    ) internal view override {
        require(!isBanned(from), "Transfer from banned address");
        require(!isBanned(to), "Transfer to banned address");
    }
}
