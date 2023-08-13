import { ethers, network } from "hardhat";
import { getLatestBlockTimestamp } from "./utils";
import { readAddressList } from "./contractAddress";

import * as dotenv from "dotenv";
dotenv.config();

async function main() {
  // Get signer's account from private key
  const pk = process.env.SEPOLIA_PRIVATE_KEY || "";
  const signer = new ethers.Wallet(pk, ethers.provider);

  const addressList = readAddressList();

  // User address to mint
  const userAddress = "0xaEd009c79E1D7978FD3B87EBe6d1f1FA3C542161";

  // Contract address
  const myNFTAddress = addressList[network.name].MyNFT;

  // Id
  const id = 1;

  // Chain id
  const chainId = await ethers.provider
    .getNetwork()
    .then((network) => network.chainId);

  const domainStruct = {
    name: "Web3Game",
    version: "1.0",
    chainId: chainId,
    verifyingContract: myNFTAddress,
  };

  const MintRequest_Type = {
    MintRequest: [
      { name: "user", type: "address" },
      { name: "id", type: "uint256" },
      { name: "validUntil", type: "uint256" },
    ],
  };

  // 100 minutes valid
  const validUntil = (await getLatestBlockTimestamp(ethers.provider)) + 100000;

  const mintRequest = {
    user: userAddress,
    id: id,
    validUntil: validUntil,
  };

  const signature = await signer._signTypedData(
    domainStruct,
    MintRequest_Type,
    mintRequest
  );

  console.log("Signature: ", signature);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
