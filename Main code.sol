// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract TimeCapsule {

    struct Capsule {
        address owner;
        string dataHash;      
        uint256 unlockTimestamp;
        uint256 createdAt;  
        string title;         
        bool isActive;
    }

    Capsule[] public capsules;

    mapping(address => uint256[]) private userCapsules;

    mapping(address => uint256) public userCapsuleCount;

    address public owner;

    uint256 public totalCapsules;

    event CapsuleCreated(
        address indexed owner,
        uint256 indexed capsuleId,
        string title,
        uint256 unlockTimestamp,
        uint256 createdAt
    );

    event CapsuleOpened(
        address indexed opener,
        uint256 indexed capsuleId,
        address indexed originalOwner
    );

    event CapsuleDeactivated(
        address indexed owner,
        uint256 indexed capsuleId
    );

    modifier onlyOwner() {
        require(msg.sender == owner, "Only contract owner can call this function");
        _;
    }

    modifier validCapsule(uint256 _capsuleId) {
        require(_capsuleId < capsules.length, "Capsule does not exist");
        require(capsules[_capsuleId].isActive, "Capsule is not active");
        _;
    }

    modifier onlyCapsuleOwner(uint256 _capsuleId) {
        require(capsules[_capsuleId].owner == msg.sender, "Not the capsule owner");
        _;
    }

    constructor() {
        owner = msg.sender;
        totalCapsules = 0;
        isPaused = false;
    }

    function createCapsule(
        string memory _dataHash,
        uint256 _unlockTimestamp,
        string memory _title
    ) external whenNotPaused returns (uint256) {

        require(bytes(_dataHash).length > 0, "Data hash cannot be empty");
        require(_unlockTimestamp > block.timestamp, "Unlock time must be in the future");
        require(_unlockTimestamp <= block.timestamp + 365 days * 10, "Unlock time too far in the future"); // Max 10 years
        require(bytes(_title).length <= 100, "Title too long (max 100 characters)");

        capsules.push(Capsule({
            owner: msg.sender,
            dataHash: _dataHash,
            unlockTimestamp: _unlockTimestamp,
            createdAt: block.timestamp,
            title: _title,
            isActive: true
        }));
        
        uint256 capsuleId = capsules.length - 1;

        userCapsules[msg.sender].push(capsuleId);
        userCapsuleCount[msg.sender]++;
        totalCapsules++;

        emit CapsuleCreated(
            msg.sender,
            capsuleId,
            _title,
            _unlockTimestamp,
            block.timestamp
        );
        
        return capsuleId;
    }

    function viewCapsule(uint256 _capsuleId) 
        external 
        whenNotPaused
        validCapsule(_capsuleId)
        returns (string memory dataHash, string memory title, address capsuleOwner, uint256 createdAt) 
    {
        Capsule memory capsule = capsules[_capsuleId];
 
        require(block.timestamp >= capsule.unlockTimestamp, "Capsule is still locked");
        
        emit CapsuleOpened(msg.sender, _capsuleId, capsule.owner);
        
        return (
            capsule.dataHash,
            capsule.title,
            capsule.owner,
            capsule.createdAt
        );
    }

    function getMyCapsules() external view returns (uint256[] memory) {
        return userCapsules[msg.sender];
    }

    function getUserCapsules(address _user) external view returns (uint256[] memory) {
        return userCapsules[_user];
    }
 
    function getCapsuleInfo(uint256 _capsuleId) 
        external 
        view 
        validCapsule(_capsuleId)
        returns (
            address capsuleOwner,
            string memory title,
            uint256 unlockTimestamp,
            uint256 createdAt,
            bool isLocked,
            bool isActive
        ) 
    {
        Capsule memory capsule = capsules[_capsuleId];
        
        return (
            capsule.owner,
            capsule.title,
            capsule.unlockTimestamp,
            capsule.createdAt,
            block.timestamp < capsule.unlockTimestamp,
            capsule.isActive
        );
    }
 
    function deactivateCapsule(uint256 _capsuleId) 
        external 
        whenNotPaused
        validCapsule(_capsuleId) 
        onlyCapsuleOwner(_capsuleId) 
    {
        require(block.timestamp < capsules[_capsuleId].unlockTimestamp, "Capsule already unlocked");
        
        capsules[_capsuleId].isActive = false;
        
        emit CapsuleDeactivated(msg.sender, _capsuleId);
    }

    function getTimeUntilUnlock(uint256 _capsuleId) 
        external 
        view 
        validCapsule(_capsuleId)
        returns (uint256 timeRemaining) 
    {
        if (block.timestamp >= capsules[_capsuleId].unlockTimestamp) {
            return 0;
        }
        return capsules[_capsuleId].unlockTimestamp - block.timestamp;
    }

    function getActiveCapsuleCount() external view returns (uint256 count) {
        for (uint256 i = 0; i < capsules.length; i++) {
            if (capsules[i].isActive) {
                count++;
            }
        }
        return count;
    }

    function getCurrentTime() external view returns (uint256) {
        return block.timestamp;
    }

    function dateToTimestamp(
        uint256 year,
        uint256 month,
        uint256 day,
        uint256 hour,
        uint256 minute
    ) external pure returns (uint256) {
        require(year >= 2024 && year <= 2034, "Year out of reasonable range");
        require(month >= 1 && month <= 12, "Invalid month");
        require(day >= 1 && day <= 31, "Invalid day");
        require(hour <= 23, "Invalid hour");
        require(minute <= 59, "Invalid minute");

        uint256 timestamp = 0;

        for (uint256 y = 1970; y < year; y++) {
            if (isLeapYear(y)) {
                timestamp += 366 days;
            } else {
                timestamp += 365 days;
            }
        }

        // Fixed: Explicitly cast to uint256 to avoid type conversion error
        uint256[12] memory daysInMonth = [
            uint256(31), uint256(28), uint256(31), uint256(30), 
            uint256(31), uint256(30), uint256(31), uint256(31), 
            uint256(30), uint256(31), uint256(30), uint256(31)
        ];
        if (isLeapYear(year)) {
            daysInMonth[1] = 29; 
        }
        
        for (uint256 m = 1; m < month; m++) {
            timestamp += daysInMonth[m - 1] * 1 days;
        }

        timestamp += (day - 1) * 1 days;
        timestamp += hour * 1 hours;
        timestamp += minute * 1 minutes;
        
        return timestamp;
    }

    function isLeapYear(uint256 year) private pure returns (bool) {
        if (year % 4 != 0) return false;
        if (year % 100 != 0) return true;
        if (year % 400 != 0) return false;
        return true;
    }

    bool public isPaused;

    modifier whenNotPaused() {
        require(!isPaused, "Contract is paused");
        _;
    }

    event ContractPaused(address indexed owner);
    event ContractUnpaused(address indexed owner);

    function emergencyPause() external onlyOwner {
        isPaused = true;
        emit ContractPaused(msg.sender);
    }

    function unpause() external onlyOwner {
        isPaused = false;
        emit ContractUnpaused(msg.sender);
    }
}
