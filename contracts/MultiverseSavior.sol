// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./interfaces/IMultiverseSavior.sol";

contract MultiverseSavior is ERC20Permit, Ownable, IMultiverseSavior {
	// MST has a total supply of 100 million
    uint256 public constant CAP = 1e8 ether;

	// List of all minters
    mapping(address => bool) public isMinter;

    // List of all burners
    mapping(address => bool) public isBurner;

	constructor() ERC20("MultiverseSavior", "MST") ERC20Permit("MultiverseSavior") {
		isMinter[_msgSender()] = true;
	}

	// ---------------------------------------------------------------------------------------- //
    // *********************************** Modifiers ****************************************** //
    // ---------------------------------------------------------------------------------------- //

    /**
     *@notice Check if the msg.sender is in the minter list
     */
    modifier validMinter(address _sender) {
        require(isMinter[_sender], "Invalid minter");
        _;
    }

    /**
     * @notice Check if the msg.sender is in the burner list
     */
    modifier validBurner(address _sender) {
        require(isBurner[_sender], "Invalid burner");
        _;
    }

    // MST has a hard cap of 100 million
    modifier notExceedCap(uint256 _amount) {
        require(
            totalSupply() + _amount <= CAP,
            "Exceeds the DEG cap (100 million)"
        );
        _;
    }

    // ---------------------------------------------------------------------------------------- //
    // *********************************** Admin Functions ************************************ //
    // ---------------------------------------------------------------------------------------- //

    /**
     * @notice Add a new minter into the minterList
     * @param _newMinter Address of the new minter
     */
    function addMinter(address _newMinter) external onlyOwner {
        require(!isMinter[_newMinter], "Already a minter");

        isMinter[_newMinter] = true;

        emit MinterAdded(_newMinter);
    }

    /**
     * @notice Remove a minter from the minterList
     * @param _oldMinter Address of the minter to be removed
     */
    function removeMinter(address _oldMinter) external onlyOwner {
        require(isMinter[_oldMinter], "Not a minter");

        isMinter[_oldMinter] = false;

        emit MinterRemoved(_oldMinter);
    }

    /**
     * @notice Add a new burner into the burnerList
     * @param _newBurner Address of the new burner
     */
    function addBurner(address _newBurner) external onlyOwner {
        require(!isBurner[_newBurner], "Already a burner");

        isBurner[_newBurner] = true;

        emit BurnerAdded(_newBurner);
    }

    /**
     * @notice Remove a minter from the minterList
     * @param _oldBurner Address of the minter to be removed
     */
    function removeBurner(address _oldBurner) external onlyOwner {
        require(isMinter[_oldBurner], "Not a burner");

        isBurner[_oldBurner] = false;

        emit BurnerRemoved(_oldBurner);
    }

    // ---------------------------------------------------------------------------------------- //
    // *********************************** Mint & Burn ********************************* //
    // ---------------------------------------------------------------------------------------- //

    /**
     * @notice Mint tokens
     * @param _account Receiver's address
     * @param _amount Amount to be minted
     */
    function mint(address _account, uint256 _amount)
        external
        validMinter(_msgSender())
        notExceedCap(_amount)
    {
        _mint(_account, _amount); // ERC20 method with an event
        emit Mint(_account, _amount);
    }

    /**
     * @notice Burn tokens
     * @param _account address
     * @param _amount amount to be burned
     */
    function burn(address _account, uint256 _amount)
        external
        validBurner(_msgSender())
    {
        _burn(_account, _amount);
        emit Burn(_account, _amount);
    }
}
