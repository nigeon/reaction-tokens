import { ethers } from "hardhat";
import { Address } from "hardhat-deploy/dist/types";

async function main(contractName: string, initializerArgs: any[]) {
  const [owner, addr1, addr2, ...addrs] = await ethers.getSigners();
  console.log("Deploying contracts with the account:", owner.address); 
  const Contract = await ethers.getContractFactory(contractName);
  const deployed = await Contract.deploy();
  await deployed.initialize(...initializerArgs);
  console.log(`${contractName} deployed to:`, deployed.address);
}

const sfHost: Address = process.env.SUPERFLUID_HOST || '';
const sfCfa: Address = process.env.SUPERFLUID_CFA || '';
const sfSuperTokenFactory: Address = process.env.SUPERFLUID_SUPERTOKENFACTORY || '';
const sfResolver: Address = process.env.SUPERFLUID_RESOLVER || '';
const sfVersion: string = process.env.SUPERFLUID_VERSION || '';

main("ReactionFactory", [sfHost, sfCfa, sfSuperTokenFactory, sfResolver, sfVersion])
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });