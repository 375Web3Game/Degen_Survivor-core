export const getLatestBlockTimestamp = async (provider: any) => {
  const blockNumBefore = await provider.getBlockNumber();
  const blockBefore = await provider.getBlock(blockNumBefore);
  return blockBefore.timestamp;
};

export const getDomainStruct = (chainId: number, verifyingContract: string) => {
  return {
    name: "Web3Game",
    version: "1.0",
    chainId: chainId,
    verifyingContract: verifyingContract,
  };
};
