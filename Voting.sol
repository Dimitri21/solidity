// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";


contract Voting is Ownable {

    struct Voter {
        bool isRegistered;
        bool hasVoted;
        uint votedProposalId;
    }

    struct Proposal {
        string description;
        uint voteCount;
    }

    enum WorkflowStatus {
        RegisteringVoters,
        ProposalsRegistrationStarted,
        ProposalsRegistrationEnded,
        VotingSessionStarted,
        VotingSessionEnded,
        VotesTallied
    }

    mapping (address => bool) public  whitelist;
    mapping (address => Voter) public voters;
    WorkflowStatus public workflowStatus;
    Proposal[] proposals;
    uint winningProposalId;
    uint numberOfProposal;

    event VoterRegistered(address voterAddress); 
    event WorkflowStatusChange(WorkflowStatus previousStatus, WorkflowStatus newStatus);
    event ProposalRegistered(uint proposalId);
    event Voted (address voter, uint proposalId);

    modifier inWhitelist() {
        require(whitelist[msg.sender], "You are not allowed");
        _;
    }

    constructor() {
        workflowStatus = WorkflowStatus.RegisteringVoters;
    } 

    function recordVoter (address _address) onlyOwner public {
        require(!whitelist[_address], "This address is already whitelisted !");
        require(workflowStatus == WorkflowStatus.RegisteringVoters, "You can't record voters");
        whitelist[_address] = true;
        voters[_address] = Voter(true, false, 0);
        emit VoterRegistered(_address);
    } 

    // Registration Session 

    function startRegistrationSession () onlyOwner public {
        require(workflowStatus == WorkflowStatus.RegisteringVoters, "You can't start a new registration session");
        workflowStatus = WorkflowStatus.ProposalsRegistrationStarted;
        proposals.push(Proposal("Vote blanc", 0));
        emit WorkflowStatusChange(WorkflowStatus.RegisteringVoters, WorkflowStatus.ProposalsRegistrationStarted);

    }

    function submitProposal (string memory _proposal) public inWhitelist {
        require(workflowStatus == WorkflowStatus.ProposalsRegistrationStarted, "You can't vote now");
        proposals.push(Proposal(_proposal, 0));
        emit ProposalRegistered(proposals.length -1);
    }

      function endRegistrationSession () onlyOwner public {
        require(workflowStatus == WorkflowStatus.ProposalsRegistrationStarted, "You can't end a registration session");
        workflowStatus = WorkflowStatus.ProposalsRegistrationEnded;
        emit WorkflowStatusChange(WorkflowStatus.ProposalsRegistrationStarted, WorkflowStatus.ProposalsRegistrationEnded);

    }

    function viewProposals () view public inWhitelist returns ( Proposal[] memory) {
        return proposals;
    }

        function viewProposalsLength () view public inWhitelist returns (uint) {
        return proposals.length;
    }

        // Voting Session 

    function startVotingSession () onlyOwner public {
        require(workflowStatus == WorkflowStatus.ProposalsRegistrationEnded, "You can't start a voting session");
        workflowStatus = WorkflowStatus.VotingSessionStarted;
        emit WorkflowStatusChange(WorkflowStatus.ProposalsRegistrationEnded, WorkflowStatus.VotingSessionStarted);

    }

    function vote (uint _proposalId) public inWhitelist returns (string memory) {
        require( !voters[msg.sender].hasVoted, "You already voted");
        proposals[_proposalId].voteCount += 1;
        voters[msg.sender].hasVoted = true;
        voters[msg.sender].votedProposalId = _proposalId;
        emit Voted (msg.sender, _proposalId);
        return ("Voted!");
    }

    function endVotingSession () onlyOwner public  returns(uint) {
        require(workflowStatus == WorkflowStatus.VotingSessionStarted, "You can't end a voting session");
        workflowStatus = WorkflowStatus.VotingSessionEnded;
        emit WorkflowStatusChange(WorkflowStatus.VotingSessionStarted, WorkflowStatus.VotingSessionEnded);


        uint maxVote;

        // Vote count 

       for(uint i = 0; i < proposals.length; i++) {
           if (proposals[i].voteCount > maxVote) {
               maxVote = proposals[i].voteCount;
               winningProposalId = i;
           }
       }

        workflowStatus = WorkflowStatus.VotesTallied;
        emit WorkflowStatusChange(WorkflowStatus.VotingSessionEnded, WorkflowStatus.VotesTallied);

        return winningProposalId;
    }

}