import {expect} from "./chai-setup";

import {ethers, deployments, getNamedAccounts, network} from 'hardhat';

// SIG MINT
// APPROVE
// TRANSFER
// BURN
// SELECT

function getDomainSeparatorV4(EIP712_DOMAIN_TYPEHASH: string, HASHED_NAME: string, HASHED_VERSION: string, chainId: number, contractAddress: string): string {
  const domainSeparator: string = ethers.utils.keccak256(
    ethers.utils.defaultAbiCoder.encode(
      ["bytes32", "bytes32", "bytes32", "uint256", "address"],
      [EIP712_DOMAIN_TYPEHASH, HASHED_NAME, HASHED_VERSION, chainId, contractAddress]
    )
  );
  return domainSeparator;
}


function getStructHash(user: string, id: number, validUntil: number): string {
  const MINT_REQUEST_TYPEHASH: string = ethers.utils.keccak256(
    ethers.utils.toUtf8Bytes("MintRequest(address user,uint256 id,uint256 validUntil)")
  );

  const structHash: string = ethers.utils.keccak256(
    ethers.utils.defaultAbiCoder.encode(
      ["bytes32", "address", "uint256", "uint256"],
      [MINT_REQUEST_TYPEHASH, user, id, validUntil]
    )
  );

  return structHash;
}

function calculateTypedDataHash(domainSeparator: string, structHash: string) {
  const typedData = ethers.utils.solidityPack(['bytes32', 'bytes32'], [domainSeparator, structHash]);
  const typedDataHash = ethers.utils.keccak256(typedData);
  return typedDataHash;
}

function hashMessage(user: string, itemId: number, validUntil: number, _contractAddress: string, chainId: number):  [string, string]{
  const EIP712_DOMAIN_TYPEHASH: string = ethers.utils.keccak256(ethers.utils.toUtf8Bytes("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"));
  const HASHED_NAME: string = ethers.utils.keccak256(ethers.utils.toUtf8Bytes("Web3Game"));
  const HASHED_VERSION: string = ethers.utils.keccak256(ethers.utils.toUtf8Bytes("1.0"));
  const contractAddress: string =  _contractAddress;
  const domainSeparator: string = getDomainSeparatorV4(EIP712_DOMAIN_TYPEHASH, HASHED_NAME, HASHED_VERSION, chainId, contractAddress);
  const structHash: string = getStructHash(user, itemId, validUntil);
  const digest: string = calculateTypedDataHash(domainSeparator, structHash);
  const msgHash = ethers.utils.hashMessage(digest);
  // console.log("domainSeparator", domainSeparator)
  // console.log("structHash", structHash)
  // console.log("digest", digest)
  // console.log("msgHash", msgHash)
  // console.log("recoveredAddress:", recoveredAddress)
  return [digest, msgHash]
}


describe("Token contract", function() {

  it("Mint NFT", async function() {
    //加载链信息
    const provider = ethers.provider;
    const network = await provider.getNetwork();
    const chainId = network.chainId;
    console.log("\n==================================")
    console.log("chainId:", chainId)

    //加载合约
    //问题1 owner是0x0000000
    await deployments.fixture(["ProxyAdmin", "MyNFT"]);
    const NFTContract = await ethers.getContractFactory("MyNFT");
    const NFTContractInstance = await NFTContract.deploy();
    const owner = await NFTContractInstance.owner();
    const name = await NFTContractInstance.name();
    const symbol = await NFTContractInstance.symbol();
    console.log("\n==================================")
    console.log("NFTContract:", NFTContractInstance.address)
    console.log("owner:", owner)
    console.log("name:", name)
    console.log("symbol:", symbol)

    //加载账户
    const [deployer_sig, user1_sig] = await ethers.getSigners();
    const {deployer, user1} = await getNamedAccounts();
    console.log("\n==================================")
    console.log("deployer:", deployer)
    console.log("user1:", user1)

    //TokenURI 设置
    //同问题1 owner是0x0000000
    const NFTContractInstance_NFTContract = NFTContractInstance.connect(user1_sig);
    // await NFTContractInstance_deployer.setBaseURI("https://api.otherside.xyz/lands/");
    const NFTContractInstance_deployer = NFTContractInstance.connect(deployer_sig);
    const baseURI = await NFTContractInstance_deployer.baseURI();
    const tokenURI = await NFTContractInstance_deployer.tokenURI(1);
    console.log("\n==================================")
    console.log("baseURI:", baseURI)
    console.log("tokenURI:", tokenURI)

    //MINT 授权
    //问题2 合约中签名解析出来的地址不对
    // await NFTContractInstance_deployer.addSigner(user);


    //MINT
    let itemId = 1;
    let user = user1;
    let validUntil = Math.floor(Date.now() / 1000)+3600;
    let [digest , msgHash] = hashMessage(user, itemId, validUntil, NFTContractInstance.address, chainId);
    let signature = await deployer_sig.signMessage(digest)
    // const recoveredAddress = ethers.utils.recoverAddress(msgHash, signature);
    await NFTContractInstance_NFTContract.mint(user, itemId, validUntil, signature);

    itemId = 31231;
    user = user1;
    validUntil = Math.floor(Date.now() / 1000)+3600;
    [digest , msgHash] = hashMessage(user, itemId, validUntil, NFTContractInstance.address, chainId);
    signature = await deployer_sig.signMessage(digest)
    // const recoveredAddress = ethers.utils.recoverAddress(msgHash, signature);
    await NFTContractInstance_NFTContract.mint(user, itemId, validUntil, signature);
    // await NFTContractInstance_NFTContract.mint(user, itemId, validUntil, signature);
    const ownerBalance = await NFTContractInstance_NFTContract.balanceOf(user1);
    const batchItemIdToTokenId = await NFTContractInstance_NFTContract.batchItemIdToTokenId([1, 31231, 12, 0]);
    const batchTokenIdToItemId = await NFTContractInstance_NFTContract.batchTokenIdToItemId([1, 2, 12, 0]);
    const tokenOfOwner = await NFTContractInstance_NFTContract.tokenOfOwner(user1, 0, 10);
    console.log("\n==================================")
    console.log("ownerBalance:", ownerBalance.toString()) 
    console.log("batchItemIdToTokenId:", batchItemIdToTokenId)
    console.log("batchTokenIdToItemId:", batchTokenIdToItemId)
    console.log("tokenOfOwner:", tokenOfOwner)
  });
});

