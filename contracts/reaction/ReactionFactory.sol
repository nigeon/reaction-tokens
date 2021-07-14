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

    event ReactionDeployed(address creator, address reactionContractAddr, address stakingToken, string reactionTokenName, string reactionTokenSymbol);

    function initialize(address sfHost, address sfCfa, address sfSuperTokenFactory, address sfResolver, string memory sfVersion) public payable initializer {
        assert(sfHost != address(0));
        assert(sfCfa != address(0));
        assert(sfSuperTokenFactory != address(0));
        assert(sfResolver != address(0));

        _sfHost = sfHost;
        _sfCfa = sfCfa;
        _sfSuperTokenFactory = sfSuperTokenFactory;
        _sfResolver = sfResolver;
        _sfVersion = sfVersion;

        owner = _msgSender();
    }

    function deployReaction(address stakingToken, string memory reactionTokenName, string memory reactionTokenSymbol) external returns (address){
        require(stakingToken != address(0));

        ReactionToken reactionContract = new ReactionToken(
            _sfHost, 
            _sfCfa, 
            stakingToken,
            _sfSuperTokenFactory, 
            reactionTokenName, 
            reactionTokenSymbol,
            _sfResolver,
            _sfVersion
        );   

        address reactionContractAddr = address(reactionContract);

        emit ReactionDeployed(_msgSender(), reactionContractAddr, stakingToken, reactionTokenName, reactionTokenSymbol);

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