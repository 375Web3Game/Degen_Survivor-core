npx hardhat deploy --network hardhat
npx hardhat test test/Test.ts --network hardhat
npx hardhat deploy --network sepolia
npx hardhat test test/Test.ts --network sepolia

export SEPOLIA_URL=https://ethereum-sepolia.blockpi.network/v1/rpc/public
export SEPOLIA_PRIVATE_KEY=0x0000000

"ProxyAdmin": "0x6B01332b1536e5B81fb1F4f1d85c8aAD9a76671d",
"MyNFT": "0x0C2f821aA0A31D4844F0B99D6Ec8C4e1D2f5662B"