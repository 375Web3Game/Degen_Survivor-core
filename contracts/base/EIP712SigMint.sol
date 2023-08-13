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
        
        // require(
        //     EIP712_DOMAIN_TYPEHASH == 0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f, 
        //     "EIP712_DOMAIN_TYPEHASH: Invalid"
        // );

        // require(
        //     HASHED_NAME == 0xdf69610c0b387da9d15be15abce6a2001b01d78457c2fe3f30ceca4e1f28ff45, 
        //     "HASHED_NAME: Invalid"
        // );

        // require(
        //     HASHED_VERSION == 0xe6bbd6277e1bf288eed5e8d1780f9a50b239e86b153736bceebccf4ea79d90b3, 
        //     "HASHED_VERSION: Invalid"
        // );

        // require(
        //     address(this) == 0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9, 
        //     "contractAddress: Invalid"
        // );
        // require(
        //     block.chainid == 31337, 
        //     "chainid: Invalid"
        // );

        // require(getDomainSeparatorV4() == 0x20eb0b348dde6b196ba3ce95551d29a9e48ee909f8861d29bb4ef4381dc6dc64,
        //     "getDomainSeparatorV4: Invalid"
        // );

        // require(getStructHash(req) == 0xb6464558d6c94052f5e862d83897b0ec1c6527236c69cae47170696252e89fe9,
        //     "structHash: Invalid"
        // );

        // require(digest == 0xd7f5981a57d96ee588f34b742d9babc618d99ee259c57fd3a2be2b82ff8bb0b8,
        //     "digest: Invalid"
        // );

        // require(
        //     // isValidSigner[recoveredAddress],
        //     recoveredAddress == 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266,
        //     "AchievementsFactory: Invalid signer"
        // );

        require(
            block.timestamp <= _validUntil,
            "AchievementsFactory: Signature expired"
        );
    }
}
