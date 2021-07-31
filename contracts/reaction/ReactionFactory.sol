// SPDX-License-Identifier: MIT
pragma solidity >=0.7.6;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/utils/Context.sol";

import {
    ISuperfluid
} from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperfluid.sol";
import "@superfluid-finance/ethereum-contracts/contracts/interfaces/misc/IResolver.sol";

import "./ReactionToken.sol";

contract ReactionFactory is Context, UUPSUpgradeable, Initializable {

    address private _sfHost; // host
    address private _sfCfa; // the stored constant flow agreement class address
    address private _sfSuperTokenFactory;
    address private _sfResolver;
    string private _sfVersion;

    IResolver internal _resolver; // Superfluid resolver

    address owner;

    mapping (address => address) public superTokenRegistry;  // token registry for non-official tokens

    event Initialized(address sfHost, address sfCfa, address sfSuperTokenFactory, address sfResolver, string sfVersion);
    event ReactionDeployed(address creator, address reactionContractAddr, string reactionTokenName, string reactionTokenSymbol, string tokenMetadataURI);

    function initialize(address sfHost, address sfCfa, address sfSuperTokenFactory, address sfResolver, string memory sfVersion) public payable initializer {
        require(address(sfHost) != address(0), "ReactionFactory: Host Address can't be 0x");
        require(address(sfCfa) != address(0), "ReactionFactory: CFA Address can't be 0x");
        require(address(sfSuperTokenFactory) != address(0), "ReactionFactory: SuperTokenFactory Address can't be 0x");
        require(address(sfResolver) != address(0), "ReactionFactory: Resolver Address can't be 0x");

        _sfHost = sfHost;
        _sfCfa = sfCfa;
        _sfSuperTokenFactory = sfSuperTokenFactory;
        _sfResolver = sfResolver;
        _sfVersion = sfVersion;

        _resolver = IResolver(sfResolver);

        owner = _msgSender();

        emit Initialized(_sfHost, _sfCfa, _sfSuperTokenFactory, _sfResolver, _sfVersion);
    }

    function deployReaction(string memory reactionTokenName, string memory reactionTokenSymbol, string memory tokenMetadataURI) external returns (address){
        ReactionToken reactionContract = new ReactionToken(
            address(this),
            _sfHost, 
            _sfCfa, 
            _sfSuperTokenFactory,
            reactionTokenName, 
            reactionTokenSymbol,
            tokenMetadataURI
        );

        address reactionContractAddr = address(reactionContract);

        emit ReactionDeployed(_msgSender(), reactionContractAddr, reactionTokenName, reactionTokenSymbol, tokenMetadataURI);

        return reactionContractAddr;
    }

    function isSuperToken(ERC20WithTokenInfo _token) public view returns (bool) {
        string memory tokenId = string(abi.encodePacked('supertokens', '.', _sfVersion, '.', _token.symbol()));
        return _resolver.get(tokenId) == address(_token);
    }

    function getSuperToken(ERC20WithTokenInfo _token) public view returns (address tokenAddress) {
        string memory tokenId = string(abi.encodePacked('supertokens', '.', _sfVersion, '.', _token.symbol(), 'x'));
        tokenAddress = _resolver.get(tokenId);

        if (tokenAddress == address(0)) { // Look on the App registry if there's already a "non-oficially registered" Supertoken
            tokenAddress = superTokenRegistry[address(_token)];
        }
    }

    function createSuperToken(ERC20WithTokenInfo _token) public returns (ISuperToken superToken) {
        if (superTokenRegistry[address(_token)] != address(0)) {
            superToken = ISuperToken(superTokenRegistry[address(_token)]);
        } else {
            ISuperTokenFactory factory = ISuperfluid(_sfHost).getSuperTokenFactory();
            string memory name = string(abi.encodePacked('Super ', _token.name()));
            string memory symbol = string(abi.encodePacked(_token.symbol(), 'x'));
            superToken = factory.createERC20Wrapper(_token, ISuperTokenFactory.Upgradability.FULL_UPGRADABE, name, symbol);
            superTokenRegistry[address(_token)] = address(superToken);
        }
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {
    }

     /* ========== MODIFIERS ========== */

    modifier onlyOwner() {
        require(msg.sender == owner, "ReactionFactory: Caller is not owner");
        _;
    }
}