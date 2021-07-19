// SPDX-License-Identifier: MIT
pragma solidity >=0.7.6;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Context.sol";

import {
    IConstantFlowAgreementV1
} from "@superfluid-finance/ethereum-contracts/contracts/interfaces/agreements/IConstantFlowAgreementV1.sol";
import "@superfluid-finance/ethereum-contracts/contracts/interfaces/misc/IResolver.sol";
import {
    ISuperfluid,
    ISuperToken,
    ISuperTokenFactory
} from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperfluid.sol";
import { ERC20WithTokenInfo } from "@superfluid-finance/ethereum-contracts/contracts/interfaces/tokens/ERC20WithTokenInfo.sol";

contract ReactionToken is Context, ERC20 {
    event Staked(address author, uint256 amount, address stakingTokenAddress, address stakingSuperTokenAddress);
    event Reacted(address author, address nftAddress, address reactionTokenAddress, uint256 amount, string reactionTokenName, string reactionTokenSymbol);

    ISuperfluid internal _host; // Superfluid host address
    IConstantFlowAgreementV1 internal _cfa; // Superfluid Constant Flow Agreement address
    ISuperTokenFactory private _superTokenFactory; // Superfluid Supertoken Factory
    IResolver internal _resolver; // Superfluid resolver
    string internal _version; // Superfluid version

    constructor(
        address host, 
        address cfa, 
        address superTokenFactory, 
        address resolver,
        string memory version,
        string memory reactionTokenName, 
        string memory reactionTokenSymbol
    ) ERC20(reactionTokenName, reactionTokenSymbol) {
        require(address(host) != address(0), "ReactionToken: Host Address can't be 0x");
        require(address(cfa) != address(0), "ReactionToken: CFA Address can't be 0x");
        require(address(superTokenFactory) != address(0), "ReactionToken: SuperTokenFactory Address can't be 0x");
        require(address(resolver) != address(0), "ReactionToken: Resolver Address can't be 0x");

        _host = ISuperfluid(host);
        _cfa =  IConstantFlowAgreementV1(cfa);
        _superTokenFactory = ISuperTokenFactory(superTokenFactory);
        _resolver = IResolver(resolver);
        _version = version;
    }

    function stakeAndMint(uint256 amount, address stakingTokenAddress, address nftAddress) public {
        require(address(stakingTokenAddress) != address(0), "ReactionToken: Staking Token Address can't be 0x");
        require(address(nftAddress) != address(0), "ReactionToken: NFT Address can't be 0x");

        ERC20WithTokenInfo stakingToken = ERC20WithTokenInfo(stakingTokenAddress);

        // Stake everything here
        IERC20(stakingToken).transferFrom(_msgSender(), address(this), amount);

        // Mint the reaction token straight to the NFT
        _mint(nftAddress, amount);

        // Get/Create the super token
        address stakingSuperToken = isSuperToken(stakingToken) ? address(stakingToken) : getSuperToken(stakingToken);
        if (stakingSuperToken == address(0)) {
            stakingSuperToken = address(createSuperToken(stakingToken));
        }

        // Approve token to be upgraded
        if (stakingToken.allowance(address(this), stakingSuperToken) < amount) {
            bool success = stakingToken.approve(stakingSuperToken, amount); // max allowance
            require(success, "ReactionToken: Failed to approve allowance to SuperToken");
        }

        // Give token Superpowers
        ISuperToken(stakingSuperToken).upgrade(amount);

        // Calculate the flow rate
        uint256 secondsInAMonth = 2592000;
        uint256 flowRate = amount/secondsInAMonth; // return the whole stake in one month

        // Create CFA
        _host.callAgreement(
            _cfa,
            abi.encodeWithSelector(
                _cfa.createFlow.selector,
                stakingSuperToken,
                _msgSender(),
                flowRate,
                new bytes(0) // placeholder
            ),
            new bytes(0)
        );

        emit Staked(_msgSender(), amount, stakingTokenAddress, stakingSuperToken);

        ERC20 reactionToken = ERC20(address(this));
        emit Reacted(_msgSender(), nftAddress, address(this), amount, reactionToken.name(), reactionToken.symbol());
    }

    function isSuperToken(ERC20WithTokenInfo _token) public view returns (bool) {
        string memory tokenId = string(abi.encodePacked('supertokens', '.', _version, '.', _token.symbol()));
        return _resolver.get(tokenId) == address(_token);
    }

    function getSuperToken(ERC20WithTokenInfo _token) public view returns (address tokenAddress) {
        string memory tokenId = string(abi.encodePacked('supertokens', '.', _version, '.', _token.symbol(), 'x'));
        tokenAddress = _resolver.get(tokenId);
    }

    function createSuperToken(ERC20WithTokenInfo _token) public returns (ISuperToken superToken) {
        ISuperTokenFactory factory = _host.getSuperTokenFactory();
        string memory name = string(abi.encodePacked('Super ', _token.name()));
        string memory symbol = string(abi.encodePacked(_token.symbol(), 'x'));
        superToken = factory.createERC20Wrapper(_token, ISuperTokenFactory.Upgradability.FULL_UPGRADABE, name, symbol);
    }
}