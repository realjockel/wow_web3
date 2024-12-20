// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/governance/Governor.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorSettings.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorCountingSimple.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorVotes.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorVotesQuorumFraction.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract GuildDAO is Governor, GovernorSettings, GovernorCountingSimple, GovernorVotes, GovernorVotesQuorumFraction {
    using SafeERC20 for IERC20;

    IERC20 public guildToken;
    mapping(uint256 => Bounty) public bounties;
    uint256 public nextBountyId;

    struct Bounty {
        string description;
        uint256 reward;
        address creator;
        bool completed;
        address claimedBy;
    }

    constructor(
        string memory guildName,
        IERC20 _token,
        uint32 _votingDelay,
        uint32 _votingPeriod,
        uint256 _proposalThreshold,
        uint256 _quorumPercentage
    )
        Governor(guildName)
        GovernorSettings(_votingDelay, _votingPeriod, _proposalThreshold)
        GovernorVotes(IVotes(address(_token)))
        GovernorVotesQuorumFraction(_quorumPercentage)
    {
        guildToken = _token;
    }

    function createBounty(string memory _description, uint256 _reward) external {
        guildToken.safeTransferFrom(msg.sender, address(this), _reward);
        bounties[nextBountyId] = Bounty(_description, _reward, msg.sender, false, address(0));
        nextBountyId++;
    }

    function completeBounty(uint256 _bountyId) external {
        Bounty storage bounty = bounties[_bountyId];
        require(!bounty.completed, "Bounty already completed");
        bounty.completed = true;
        bounty.claimedBy = msg.sender;
        guildToken.safeTransfer(msg.sender, bounty.reward);
    }

    function stake(uint256 _amount) external {
        guildToken.safeTransferFrom(msg.sender, address(this), _amount);
    }

    // The following functions are overrides required by Solidity.

    function proposalThreshold()
        public
        view
        override(Governor, GovernorSettings)
        returns (uint256)
    {
        return super.proposalThreshold();
    }
}
