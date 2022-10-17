// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";

contract Voting is Ownable {
    struct Voter {
        bool isRegistered;
        bool hasVoted;
        uint256 votedProposalId;
    }

    struct Proposal {
        string description;
        uint256 voteCount;
    }

    enum WorkflowStatus {
        RegisteringVoters,
        ProposalsRegistrationStarted,
        ProposalsRegistrationEnded,
        VotingSessionStarted,
        VotingSessionEnded,
        VotesTallied
    }

    mapping(address => bool) public whitelist;
    mapping(address => Voter) public voters;
    WorkflowStatus public workflowStatus;
    Proposal[] proposals;
    uint256 winningProposalId;
    uint256 numberOfProposal;

    event VoterRegistered(address voterAddress);
    event WorkflowStatusChange(
        WorkflowStatus previousStatus,
        WorkflowStatus newStatus
    );
    event ProposalRegistered(uint256 proposalId);
    event Voted(address voter, uint256 proposalId);

    modifier inWhitelist() {
        require(whitelist[msg.sender], "You are not allowed");
        _;
    }

    constructor() {
        workflowStatus = WorkflowStatus.RegisteringVoters;
    }

    function recordVoter(address _address) public onlyOwner {
        require(!whitelist[_address], "This address is already whitelisted !");
        require(
            workflowStatus == WorkflowStatus.RegisteringVoters,
            "You can't record voters"
        );
        whitelist[_address] = true;
        voters[_address] = Voter(true, false, 0);
        emit VoterRegistered(_address);
    }

    // Registration Session

    function startRegistrationSession() public onlyOwner {
        require(
            workflowStatus == WorkflowStatus.RegisteringVoters,
            "You can't start a new registration session"
        );
        workflowStatus = WorkflowStatus.ProposalsRegistrationStarted;
        proposals.push(Proposal("Blank vote", 0));
        emit WorkflowStatusChange(
            WorkflowStatus.RegisteringVoters,
            WorkflowStatus.ProposalsRegistrationStarted
        );
    }

    function submitProposal(string memory _proposal) public inWhitelist {
        require(
            workflowStatus == WorkflowStatus.ProposalsRegistrationStarted,
            "You can't vote now"
        );
        proposals.push(Proposal(_proposal, 0));
        emit ProposalRegistered(proposals.length - 1);
    }

    function endRegistrationSession() public onlyOwner {
        require(
            workflowStatus == WorkflowStatus.ProposalsRegistrationStarted,
            "You can't end a registration session"
        );
        workflowStatus = WorkflowStatus.ProposalsRegistrationEnded;
        emit WorkflowStatusChange(
            WorkflowStatus.ProposalsRegistrationStarted,
            WorkflowStatus.ProposalsRegistrationEnded
        );
    }

    function viewProposals()
        public
        view
        inWhitelist
        returns (Proposal[] memory)
    {
        return proposals;
    }

    function viewProposalsLength() public view inWhitelist returns (uint256) {
        return proposals.length;
    }

    function viewVote(address _address)
        public
        view
        inWhitelist
        returns (Voter memory)
    {
        return voters[_address];
    }

    // Voting Session

    function startVotingSession() public onlyOwner {
        require(
            workflowStatus == WorkflowStatus.ProposalsRegistrationEnded,
            "You can't start a voting session"
        );
        workflowStatus = WorkflowStatus.VotingSessionStarted;
        emit WorkflowStatusChange(
            WorkflowStatus.ProposalsRegistrationEnded,
            WorkflowStatus.VotingSessionStarted
        );
    }

    function vote(uint256 _proposalId)
        public
        inWhitelist
        returns (string memory)
    {
        require(!voters[msg.sender].hasVoted, "You already voted");
        proposals[_proposalId].voteCount += 1;
        voters[msg.sender].hasVoted = true;
        voters[msg.sender].votedProposalId = _proposalId;
        emit Voted(msg.sender, _proposalId);
        return ("Voted!");
    }

    function endVotingSession() public onlyOwner {
        require(
            workflowStatus == WorkflowStatus.VotingSessionStarted,
            "You can't end a voting session"
        );
        workflowStatus = WorkflowStatus.VotingSessionEnded;
        emit WorkflowStatusChange(
            WorkflowStatus.VotingSessionStarted,
            WorkflowStatus.VotingSessionEnded
        );
    }

    function VotesTallied() public onlyOwner returns (uint id) {
        uint256 maxVote;

        // Vote count

        for (uint256 i = 0; i < proposals.length; i++) {
            if (proposals[i].voteCount > maxVote) {
                maxVote = proposals[i].voteCount;
                winningProposalId = i;
            }
        }

        workflowStatus = WorkflowStatus.VotesTallied;
        emit WorkflowStatusChange(
            WorkflowStatus.VotingSessionEnded,
            WorkflowStatus.VotesTallied
        );

        // Check if majority

        if (maxVote <= proposals.length / 2) {
            revert("Any proposal has a majority");
        }

        if (maxVote > proposals.length / 2) {
            return winningProposalId;
        }
    }
}
