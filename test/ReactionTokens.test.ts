import "@nomiclabs/hardhat-ethers";
import { expect } from "chai";
import { ethers } from "hardhat";
import { BigNumber, Contract } from "ethers";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { Address } from "hardhat-deploy/dist/types";

describe("Reaction Tokens", function () {
    let owner: SignerWithAddress,
        alice: SignerWithAddress,
        bob: SignerWithAddress,
        addrs: SignerWithAddress[];

    let erc20Contract: Contract;
    let erc721Contract: Contract;

    // SuperFluid config (Goerli)
    const sfHost: Address = "0x22ff293e14F1EC3A09B137e9e06084AFd63adDF9";
    const sfCfa: Address = "0xEd6BcbF6907D4feEEe8a8875543249bEa9D308E8";
    const sfSuperTokenFactory: Address = "0x94f26B4c8AD12B18c12f38E878618f7664bdcCE2";
    const sfResolver: Address = "0x3710AB3fDE2B61736B8BB0CE845D6c61F667a78E";
    const sfVersion: string = "1";

    beforeEach(async function () {
        // Get some signers
        [owner, alice, bob, ...addrs] = await ethers.getSigners();

        // Deploy a dummy ERC20 token to be used later
        const dummyErc20Name = "DummyErc20";
        const contractFactory = await ethers.getContractFactory(dummyErc20Name);
        erc20Contract = await contractFactory.deploy(ethers.utils.parseEther("10000"));

        expect(erc20Contract.address).to.be.properAddress;
        expect(await erc20Contract.name()).to.be.equal(dummyErc20Name);

        // Deploy a dummy ERC721(nft) token to be used later
        const dummyErc721Name = "DummyErc721";
        const contractNftFactory = await ethers.getContractFactory(dummyErc721Name);
        erc721Contract = await contractNftFactory.deploy();
        await erc721Contract.mint(23);

        expect(erc721Contract.address).to.be.properAddress;
        expect(await erc721Contract.name()).to.be.equal(dummyErc721Name);
    });

    it("Should have multiple siners with balance > 0", async function () {
        expect(owner.address).to.not.equal(alice.address);
        expect(owner.address).to.not.equal(bob.address);
        expect(alice.address).to.not.equal(bob.address);

        // expect((await owner.getBalance()).toString()).to.be.equal(ethers.utils.parseEther("10000")); // Owner deployed the DummyERC20
        expect((await bob.getBalance()).toString()).to.be.equal(ethers.utils.parseEther("10000"));
        expect((await alice.getBalance()).toString()).to.be.equal(ethers.utils.parseEther("10000"));
    });

    it("Should deploy a new Reaction Factory Contract", async function () {
        // Deploy Reaction Factory
        const contractFactory = await ethers.getContractFactory("ReactionFactory");
        let reactionFactoryContract: Contract = await contractFactory.deploy();
        expect(reactionFactoryContract.address).to.be.properAddress;

        // Init Factory
        reactionFactoryContract.initialize(sfHost, sfCfa, sfSuperTokenFactory, sfResolver, sfVersion);

        // // Deploy new Reaction Token
        const stakingToken: Address = erc20Contract.address;
        const reactionTokenName: string = 'Like';
        const reactionTokenSymbol: string = 'LIKE';
        
        let tx = await reactionFactoryContract.deployReaction(stakingToken, reactionTokenName, reactionTokenSymbol);
        let receipt = await tx.wait();
        receipt = receipt.events?.filter((x: any) => {return x.event == "ReactionDeployed"})[0];
        
        expect(receipt.args.creator).to.be.equal(owner.address);
        expect(receipt.args.reactionContractAddr).to.be.properAddress;
        expect(receipt.args.stakingToken).to.be.equal(stakingToken);
        expect(receipt.args.reactionTokenName).to.be.equal(reactionTokenName);
        expect(receipt.args.reactionTokenSymbol).to.be.equal(reactionTokenSymbol);
    });

    it("Should Stake & Mint some reaction tokens", async function () {
        // Deploy Reaction Factory
        const contractFactory = await ethers.getContractFactory("ReactionFactory");
        const reactionFactoryContract: Contract = await contractFactory.deploy();

        // Init Factory
        reactionFactoryContract.initialize(sfHost, sfCfa, sfSuperTokenFactory, sfResolver, sfVersion);

        // Deploy new Reaction Token
        const stakingToken: Address = erc20Contract.address;
        const stakingAmount: BigNumber = ethers.utils.parseEther("1000");
        const reactionTokenName: string = 'Like';
        const reactionTokenSymbol: string = 'LIKE';
        
        let tx = await reactionFactoryContract.deployReaction(stakingToken, reactionTokenName, reactionTokenSymbol);
        let receipt = await tx.wait();
        receipt = receipt.events?.filter((x: any) => {return x.event == "ReactionDeployed"})[0];

        let reactionTokenContractAddr: Address = receipt.args.reactionContractAddr;
        expect(reactionTokenContractAddr).to.be.properAddress;

        const reactionTokenContract = await ethers.getContractAt("ReactionToken", reactionTokenContractAddr);

        // Approve tokens sending
        await expect(erc20Contract.approve(reactionTokenContract.address, stakingAmount))
            .to.emit(erc20Contract, "Approval");

        await expect(reactionTokenContract.stakeAndMint(stakingAmount, erc721Contract.address))
            .to.emit(reactionTokenContract, "Staked")
            .withArgs(owner.address, stakingAmount, stakingAmount);

        expect(await reactionTokenContract.balanceOf(erc721Contract.address)).to.equal(stakingAmount);
        
        // Staking with no approval
        await expect(reactionTokenContract.stakeAndMint(stakingAmount, erc721Contract.address)).to.be.revertedWith("ERC20: transfer amount exceeds allowance");

        // Staking a bit more
        await expect(erc20Contract.approve(reactionTokenContract.address, stakingAmount))
            .to.emit(erc20Contract, "Approval");

        await expect(reactionTokenContract.stakeAndMint(stakingAmount, erc721Contract.address))
            .to.emit(reactionTokenContract, "Staked")
            .withArgs(owner.address, stakingAmount, stakingAmount.mul(2));

        expect(await reactionTokenContract.balanceOf(erc721Contract.address)).to.equal(stakingAmount.mul(2));
    });

});