import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import {expect} from "./chai-setup";

import {ethers, deployments, getNamedAccounts, network} from 'hardhat';

async function signMessage(chainId: number, contractAddress: string, userAddress: string, itemId: number, validUntil: number, signer): string {
  const domainStruct = {
    name: "Web3Game",
    version: "1.0",
    chainId: chainId,
    verifyingContract: contractAddress,
  };
  
  const MintRequest_Type = {
    MintRequest: [
      { name: "user", type: "address" },
      { name: "id", type: "uint256" },
      { name: "validUntil", type: "uint256" },
    ],
  };

  const mintRequest = {
    user: userAddress,
    id: itemId,
    validUntil: validUntil,
  };

  const signature = await signer._signTypedData(
    domainStruct,
    MintRequest_Type,
    mintRequest
  );

  return signature;
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
    await deployments.fixture(["ProxyAdmin", "MyNFT"]);
    const NFTContract = await ethers.getContractFactory("MyNFT");
    const NFTContractInstance = await NFTContract.deploy();
    await NFTContractInstance.initialize("Web3Game", "WG");
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
    //调用一下initialize
    const NFTContractInstance_NFTContract = NFTContractInstance.connect(user1_sig);
    const NFTContractInstance_deployer = NFTContractInstance.connect(deployer_sig);
    await NFTContractInstance_deployer.setBaseURI("https://api.otherside.xyz/lands/");
    const baseURI = await NFTContractInstance_deployer.baseURI();
    const tokenURI = await NFTContractInstance_deployer.tokenURI(1);
    console.log("\n==================================")
    console.log("baseURI:", baseURI)
    console.log("tokenURI:", tokenURI)

    //MINT 授权
    await NFTContractInstance_deployer.addSigner(deployer);
    
    //MINT
    // 问题2 合约中签名解析出来的地址不对
    let itemId = 1111;
    let user = user1;
    let validUntil = Math.floor(Date.now() / 1000)+3600;
    let signature = await signMessage(chainId, NFTContractInstance.address, user, itemId, validUntil, deployer_sig);
    await NFTContractInstance_NFTContract.mint(user, itemId, validUntil, signature);

    itemId = 2222;
    user = user1;
    validUntil = Math.floor(Date.now() / 1000)+3600;
    signature = await signMessage(chainId, NFTContractInstance.address, user, itemId, validUntil, deployer_sig);
    await NFTContractInstance_NFTContract.mint(user, itemId, validUntil, signature);

    //Batch MINT
    
    let itemIds = [3333, 4444, 5555, 6666];
    user = user1;
    validUntil = Math.floor(Date.now() / 1000)+3600;
    let signatures = []
    for (let i = 0; i < itemIds.length; i++) {
      const signature = await signMessage(chainId, NFTContractInstance.address, user, itemIds[i], validUntil, deployer_sig);
      signatures.push(signature);
    }
    await NFTContractInstance_NFTContract.batchMint(user, itemIds, validUntil, signatures);


    const ownerBalance = await NFTContractInstance_NFTContract.balanceOf(user1);
    const batchItemIdToTokenId = await NFTContractInstance_NFTContract.batchItemIdToTokenId([1111, 2222, 3333, 0]);
    const batchTokenIdToItemId = await NFTContractInstance_NFTContract.batchTokenIdToItemId([1, 2, 1111, 0]);
    const tokenOfOwner = await NFTContractInstance_NFTContract.tokenOfOwner(user1, 0, 10);
    console.log("\n==================================")
    console.log("ownerBalance:", ownerBalance.toString()) 
    console.log("batchItemIdToTokenId:", batchItemIdToTokenId)
    console.log("batchTokenIdToItemId:", batchTokenIdToItemId)
    console.log("tokenOfOwner:", tokenOfOwner)
  });
});

