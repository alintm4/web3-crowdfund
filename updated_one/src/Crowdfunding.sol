// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract Crowdfunding {
    string public name;
    string public description;
    address public owner;
    uint256 public goal;
    uint256 public deadline;
    bool public paused;

    struct Tier {
        string name;
        uint256 amount;
        uint256 backers;
    }
    struct Backer{
        uint256 totalContribution;
        mapping (uint256 => bool) fundedTiers;
    }
    Tier[] public tiers;
    mapping(address=> Backer) public backers;

    enum CampaignState{Active,Successful,Failed}
    CampaignState public state;

    constructor(address _owner,string memory _name, string memory _description ,uint256 _goal, uint256 _durationInDays){
    name=_name;
    description=_description;
    owner=_owner;
    deadline=block.timestamp+(_durationInDays* 1 days);
    goal=_goal;
    state=CampaignState.Active;
    }

    function checkAndUpdateCampaignState() internal {
        if(state == CampaignState.Active) {
            if(block.timestamp >= deadline) {
                state = address(this).balance >= goal ? CampaignState.Successful : CampaignState.Failed;            
            } else {
                state = address(this).balance >= goal ? CampaignState.Successful : CampaignState.Active;
            }
        }
    }

    modifier onlyOwner() {
        require(msg.sender==owner,"Only owner is allowed!");
        _;
    }

    modifier campaignOpen() {
        require(state == CampaignState.Active, "Campaign is not active.");
        _;
    }

    modifier notPaused() {
        require(!paused, "Contract is paused.");
        _;
    }

    function fund(uint256 _tierIndex) public payable campaignOpen notPaused {
        //require(msg.value>0,"Fund must be greater than zero");

        require(_tierIndex < tiers.length, "Invalid tier.");
        //require(camp_index<fundss.length,"The campaign doesn't exist.");

        require(msg.value == tiers[_tierIndex].amount, "Incorrect amount.");

        tiers[_tierIndex].backers++;
        backers[msg.sender].totalContribution += msg.value;
        backers[msg.sender].fundedTiers[_tierIndex] = true;

        checkAndUpdateCampaignState();
    }

    function addTier(string memory _name,uint256 _amount) public onlyOwner {
        require(_amount > 0, "Amount must be greater than 0.");
        tiers.push(Tier(_name, _amount, 0));
    }

     function removeTier(uint256 _index) public onlyOwner {
        require(_index < tiers.length, "Tier does not exist.");
        tiers[_index] = tiers[tiers.length -1];
        tiers.pop();
    }

    function withdraw() public onlyOwner{ 
        // require(msg.sender==owner,"Only owner allowed!");
        //require(address(this).balance>=goal,"Goal hasn't reached yet");
        
        checkAndUpdateCampaignState();
        require(state == CampaignState.Successful, "Campaign not successful.");

        uint256 balance = address(this).balance;
        require(balance > 0, "No balance to withdraw");

        payable(owner).transfer(balance);
    }

    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function refund() public payable {
        checkAndUpdateCampaignState();
        require(state == CampaignState.Failed, "Refunds not available.");
        uint256 amount = backers[msg.sender].totalContribution;
        require(amount > 0, "No contribution to refund");

        backers[msg.sender].totalContribution = 0;
        payable(msg.sender).transfer(amount);
    }

     function hasFundedTier(address _backer, uint256 _tierIndex) public view returns (bool) {
        return backers[_backer].fundedTiers[_tierIndex];
    }

    function togglePause() public onlyOwner {
        paused = !paused;
    }

    function extendDeadline(uint256 _daysToAdd) public onlyOwner campaignOpen {
        deadline += _daysToAdd * 1 days;
    }

    function getCampaignStatus() public view returns (CampaignState) {
        if (state == CampaignState.Active && block.timestamp > deadline) {
            return address(this).balance >= goal ? CampaignState.Successful : CampaignState.Failed;
        }
        return state;
    }

    function getTiers() public view returns (Tier[] memory) {
        return tiers;
    }

}
