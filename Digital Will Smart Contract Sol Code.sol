
pragma solidity ^0.8.0;

contract DigitalWill {
    address public owner;
    address public beneficiary;
    uint256 public releaseTime;
    bool public isClaimed;

    event WillCreated(address indexed owner, address indexed beneficiary, uint256 releaseTime, uint256 value);
    event BeneficiaryUpdated(address indexed newBeneficiary);
    event WillRevoked(address indexed owner);
    event FundsClaimed(address indexed beneficiary, uint256 amount);
    event OwnerChanged(address indexed oldOwner, address indexed newOwner);
    event OwnershipRenounced(address indexed oldOwner);
    event FundsDeposited(address indexed from, uint256 amount);
    event ReleaseTimeExtended(uint256 newReleaseTime);

    constructor(address _beneficiary, uint256 _releaseTime) payable {
        require(msg.value > 0, "Funds must be provided");
        require(_releaseTime > block.timestamp, "Release time must be in the future");

        owner = msg.sender;
        beneficiary = _beneficiary;
        releaseTime = _releaseTime;
        isClaimed = false;

        emit WillCreated(owner, beneficiary, releaseTime, msg.value);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }

    modifier onlyBeneficiary() {
        require(msg.sender == beneficiary, "Only the beneficiary can claim");
        _;
    }

    modifier willNotClaimed() {
        require(!isClaimed, "Funds already claimed");
        _;
    }

    modifier beforeReleaseTime() {
        require(block.timestamp < releaseTime, "Action not allowed after release time");
        _;
    }

    modifier afterReleaseTime() {
        require(block.timestamp >= releaseTime, "Funds are still locked");
        _;
    }

    function claim() external onlyBeneficiary afterReleaseTime willNotClaimed {
        _claimFunds(beneficiary);
    }

    function updateBeneficiary(address _newBeneficiary) external onlyOwner beforeReleaseTime {
        require(_newBeneficiary != address(0), "Invalid beneficiary address");
        beneficiary = _newBeneficiary;

        emit BeneficiaryUpdated(_newBeneficiary);
    }

    function revokeWill() external onlyOwner beforeReleaseTime willNotClaimed {
        _claimFunds(owner);
        emit WillRevoked(owner);
    }

    function extendReleaseTime(uint256 _newReleaseTime) external onlyOwner beforeReleaseTime {
        require(_newReleaseTime > releaseTime, "New release time must be later than current");
        releaseTime = _newReleaseTime;

        emit ReleaseTimeExtended(_newReleaseTime);
    }

    function depositMoreFunds() external payable onlyOwner {
        require(msg.value > 0, "No ETH sent");
        emit FundsDeposited(msg.sender, msg.value);
    }

    function changeOwner(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "Invalid address");
        emit OwnerChanged(owner, _newOwner);
        owner = _newOwner;
    }

    function renounceOwnership() external onlyOwner {
        emit OwnershipRenounced(owner);
        owner = address(0);
    }

    function isWillActive() external view returns (bool) {
        return !isClaimed && block.timestamp < releaseTime;
    }

    function getWillDetails() external view returns (
        address _owner,
        address _beneficiary,
        uint256 _releaseTime,
        uint256 _balance,
        bool _isClaimed
    ) {
        return (owner, beneficiary, releaseTime, address(this).balance, isClaimed);
    }

    /*** Internal functions ***/

    function _claimFunds(address to) internal {
        isClaimed = true;
        uint256 amount = address(this).balance;
        payable(to).transfer(amount);

        emit FundsClaimed(to, amount);
    }
}
