const { ethers } = require("hardhat");

const address = '0xB15802beA23Baee027eC202D33BaF8Ac95058710';
const url = "https://polygon-rpc.com";
const provider = new ethers.providers.JsonRpcProvider(url);

async function main() {
    const contract = await hre.ethers.getContractAt("HashTest", address);

    const blockNumber = await provider.getBlockNumber();
    console.log(blockNumber);
    const block_one = await provider.getBlock(blockNumber);
    const block_two = await provider.getBlock(blockNumber - 1);
      const handNum = ethers.utils.toUtf8Bytes("47");
      const startBalance = ethers.utils.toUtf8Bytes("100");
      const oppStartBalance = ethers.utils.toUtf8Bytes("100");
      const position = ethers.utils.toUtf8Bytes("firsttoact");
    
    const megaHash = ethers.utils.keccak256(ethers.utils.concat([block_one.hash, block_two.hash, handNum, startBalance, oppStartBalance, position]));
    console.log(megaHash);

    const testArray = [blockNumber, blockNumber - 1];
    const stringArr = ["47", "100", "100", "firsttoact"];
    console.log(testArray);

    const hashTest = await contract.testHash(testArray, stringArr, megaHash);
      console.log(hashTest);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });