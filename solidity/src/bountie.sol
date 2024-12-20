// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./token.sol";

contract BountyNFT is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    WowToken public wowToken;

    struct Bounty {
        address creator;
        address target;
        uint256 amount;
        bool claimed;
    }

    mapping(uint256 => Bounty) public bounties;

    event BountyCreated(uint256 indexed tokenId, address indexed creator, address indexed target, uint256 amount);
    event BountyClaimed(uint256 indexed tokenId, address indexed claimer, address indexed killer);

    constructor(address _wowTokenAddress) ERC721("BountyNFT", "BNFT") {
        wowToken = WowToken(_wowTokenAddress);
    }

    function createBounty(address target, uint256 amount) external returns (uint256) {
        require(wowToken.balanceOf(msg.sender) >= amount, "Insufficient WOW token balance");
        
        wowToken.transferFrom(msg.sender, address(this), amount);

        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();

        _safeMint(msg.sender, newTokenId);
        bounties[newTokenId] = Bounty(msg.sender, target, amount, false);

        emit BountyCreated(newTokenId, msg.sender, target, amount);
        return newTokenId;
    }

    function claimBounty(uint256 tokenId, address killer) external onlyOwner {
        Bounty storage bounty = bounties[tokenId];
        require(!bounty.claimed, "Bounty already claimed");

        bounty.claimed = true;
        wowToken.transfer(killer, bounty.amount);

        // Transfer the NFT ownership to the killer
        _transfer(ownerOf(tokenId), killer, tokenId);

        emit BountyClaimed(tokenId, msg.sender, killer);
    }


    function getBounty(uint256 tokenId) external view returns (Bounty memory) {
        return bounties[tokenId];
    }
}
