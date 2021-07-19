// SPDX-License-Identifier: MIT
pragma solidity >=0.7.6;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "./ReactionToken.sol";

contract ReactionFactory is Context, UUPSUpgradeable, Initializable {

    address private _sfHost; // host
    address private _sfCfa; // the stored constant flow agreement class address
    address private _sfSuperTokenFactory;
    address private _sfResolver;
    string private _sfVersion;

    address owner;

    event Initialized(address sfHost, address sfCfa, address sfSuperTokenFactory, address sfResolver, string sfVersion);
    event ReactionDeployed(address creator, address reactionContractAddr, string reactionTokenName, string reactionTokenSymbol);

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

        owner = _msgSender();

        emit Initialized(_sfHost, _sfCfa, _sfSuperTokenFactory, _sfResolver, _sfVersion);
    }

    function deployReaction(string memory reactionTokenName, string memory reactionTokenSymbol) external returns (address){
        ReactionToken reactionContract = new ReactionToken(
            _sfHost, 
            _sfCfa, 
            _sfSuperTokenFactory, 
            _sfResolver,
            _sfVersion,
            reactionTokenName, 
            reactionTokenSymbol
        );

        address reactionContractAddr = address(reactionContract);

        emit ReactionDeployed(_msgSender(), reactionContractAddr, reactionTokenName, reactionTokenSymbol);

        return reactionContractAddr;
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