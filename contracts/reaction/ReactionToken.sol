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
    event Staked(address author, uint256 amount, uint256 totalStaked);

    ISuperfluid internal _host; // Superfluid host address
    IConstantFlowAgreementV1 internal _cfa; // Superfluid Constant Flow Agreement address
    IResolver internal _resolver; // Superfluid resolver
    string internal _version; // Superfluid version

    ERC20WithTokenInfo private _stakingToken;
    address private _stakingSuperToken;
    address private _streamerAddr;

    ISuperTokenFactory private _superTokenFactory;

    int96 private _flowRate = 385802469135802; // 1000 per month

    mapping(address => uint256) private _staked;

    constructor(
        address host, 
        address cfa, 
        address stakingToken,
        address superTokenFactory, 
        string memory reactionTokenName, 
        string memory reactionTokenSymbol,
        address resolver,
        string memory version
    ) ERC20(reactionTokenName, reactionTokenSymbol) {
        assert(address(host) != address(0));
        assert(address(cfa) != address(0));
        assert(address(stakingToken) != address(0));
        assert(address(superTokenFactory) != address(0));
        assert(address(resolver) != address(0));

        _host = ISuperfluid(host);
        _cfa =  IConstantFlowAgreementV1(cfa);
        _resolver = IResolver(resolver);
        _version = version;
        
        _stakingToken = ERC20WithTokenInfo(stakingToken);
        _superTokenFactory = ISuperTokenFactory(superTokenFactory);
    }

    function stakeAndMint(uint256 amount, address nftAddress) public {
        require(address(nftAddress) != address(0));

        // Stake everything here
        // I think we can remove this as we'll wrap it as SuperToken (and that will transfer())
        IERC20(_stakingToken).transferFrom(_msgSender(), address(this), amount);
        _staked[_msgSender()] = _staked[_msgSender()] + amount;

        // Mint the reaction token straight to the NFT
        _mint(nftAddress, amount);

        // Get/Create the super token
        _stakingSuperToken = ReactionToken.isSuperToken(_stakingToken) ? address(_stakingToken) : ReactionToken.getSuperToken(_stakingToken);
        if (_stakingSuperToken == address(0)) {
            _stakingSuperToken = address(ReactionToken.createSuperToken(_stakingToken));
        }

        // Approve token to be upgraded
        if (_stakingToken.allowance(address(this), _stakingSuperToken) < amount) {
            bool success = _stakingToken.approve(_stakingSuperToken, amount); // max allowance
            require(success, "ReactionToken: failed to approve allowance to SuperToken");
        }

        // Give token Superpowers
        ISuperToken(_stakingSuperToken).upgrade(amount);

        // Create CFA
        _host.callAgreement(
            _cfa,
            abi.encodeWithSelector(
                _cfa.createFlow.selector,
                _stakingSuperToken,
                _msgSender(),
                _flowRate,
                new bytes(0) // placeholder
            ),
            "0x"
        );

        emit Staked(_msgSender(), amount, _staked[_msgSender()]);
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