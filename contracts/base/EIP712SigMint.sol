// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";

abstract contract EIP712SigMint {
    using ECDSAUpgradeable for bytes32;

    // EIP712 related variables
    // When updating the contract, directly update these constants
    bytes32 public constant EIP712_DOMAIN_TYPEHASH =
        keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
    bytes32 public constant HASHED_NAME = keccak256(bytes("Web3Game"));
    bytes32 public constant HASHED_VERSION = keccak256(bytes("1.0"));

    struct MintRequest {
        address user; // User address
        uint256 id; // Id to mint
        uint256 validUntil; // Signature is valid until this timestamp
    }
    bytes32 public constant MINT_REQUEST_TYPEHASH =
        keccak256("MintRequest(address user,uint256 id,uint256 validUntil)");

    mapping(address => bool) public isValidSigner;

    event SignerAdded(address newSigner);
    event SignerRemoved(address oldSigner);

    function getDomainSeparatorV4()
        public
        view
        returns (bytes32 domainSeparator)
    {
        domainSeparator = keccak256(
            abi.encode(
                EIP712_DOMAIN_TYPEHASH,
                HASHED_NAME,
                HASHED_VERSION,
                block.chainid,
                address(this)
            )
        );
    }

    function getStructHash(
        MintRequest memory _mintRequest
    ) public pure returns (bytes32 structHash) {
        structHash = keccak256(
            abi.encode(
                MINT_REQUEST_TYPEHASH,
                _mintRequest.user,
                _mintRequest.id,
                _mintRequest.validUntil
            )
        );
    }

    function _addSigner(address _signer) internal {
        isValidSigner[_signer] = true;
        emit SignerAdded(_signer);
    }

    function _removeSigner(address _signer) internal {
        isValidSigner[_signer] = false;
        emit SignerRemoved(_signer);
    }

    function _checkEIP712Signature(
        address _user,
        uint256 _id,
        uint256 _validUntil,
        bytes calldata _signature
    ) public view {
        MintRequest memory req = MintRequest({
            user: _user,
            id: _id,
            validUntil: _validUntil
        });

        bytes32 digest = getDomainSeparatorV4().toTypedDataHash(
            getStructHash(req)
        );

        address recoveredAddress = digest.recover(_signature);

        require(
            isValidSigner[recoveredAddress],
            "AchievementsFactory: Invalid signer"
        );

        require(
            block.timestamp <= _validUntil,
            "AchievementsFactory: Signature expired"
        );
    }
}
