// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IMultiverseSavior is IERC20, IERC20Permit {
	event MinterAdded(address newMinter);
    event MinterRemoved(address oldMinter);

    event BurnerAdded(address newBurner);
    event BurnerRemoved(address oldBurner);

    event Mint(address indexed account, uint256 amount);
    event Burn(address indexed account, uint256 amount);

    // ---------------------------------------------------------------------------------------- //
    // *************************************** Functions ************************************** //
    // ---------------------------------------------------------------------------------------- //
    function CAP() external view returns (uint256);

    /**
     * @notice Mint degis tokens
     * @param  _account Receiver's address
     * @param  _amount Amount to be minted
     */
    function mint(address _account, uint256 _amount) external;

    /**
     * @notice Burn degis tokens
     * @param  _account Receiver's address
     * @param  _amount Amount to be burned
     */
    function burn(address _account, uint256 _amount) external;
}
