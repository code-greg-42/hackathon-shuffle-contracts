async function main() {

  const shuffleContract = await hre.ethers.getContractFactory("ShuffleP2P");
  const contract = await shuffleContract.deploy();
  console.log("Deploying ShuffleP2P contract...");
  console.log(contract.address);
  await contract.deployed();

  console.log(`ShuffleP2P contract deployed to ${contract.address}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
