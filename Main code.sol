// SPDX-License-Identifier: MIT
// Specifies the license under which the code is released. MIT is a permissive open-source license.
pragma solidity ^0.8.20;
// Declares the Solidity compiler version to be used.
// The caret (^) means it will compile with versions from 0.8.20 up to (but not including) 0.9.0.

contract TimeCapsule {
    // Defines the smart contract named TimeCapsule.

    struct Capsule {
        // Defines a structure named 'Capsule' to hold the data for each time capsule.
        address owner;
        // Stores the address of the user who created this specific time capsule.
        string dataHash;
        // Stores a cryptographic hash of the actual content of the time capsule (e.g., an IPFS hash).
        // The actual data is stored off-chain, and only its hash is on-chain for integrity verification.
        uint256 unlockTimestamp;
        // The Unix timestamp (seconds since Jan 1, 1970 UTC) at which the capsule can be opened.
        uint256 createdAt;
        // The Unix timestamp when this capsule was created on the blockchain.
        string title;
        // A short descriptive title for the time capsule.
        bool isActive;
        // A boolean flag indicating if the capsule is still active (true) or has been deactivated (false).
    }

    Capsule[] public capsules;
    // Declares a public dynamic array named 'capsules' to store all the 'Capsule' structs created.
    // 'public' creates an automatic getter function (e.g., capsules(0)) to retrieve a capsule by its ID (index).

    mapping(address => uint256[]) private userCapsules;
    // Declares a private mapping that links a user's address to a dynamic array of capsule IDs (uint256).
    // This allows efficient retrieval of all capsules owned by a specific user. 'private' means no automatic getter.

    mapping(address => uint256) public userCapsuleCount;
    // Declares a public mapping to store the total number of active capsules created by each user.

    address public owner;
    // Declares a public state variable 'owner' of type 'address'.
    // This will be the address of the contract deployer, acting as an administrative owner.

    uint256 public totalCapsules;
    // Declares a public state variable 'totalCapsules' of type 'uint256'.
    // Keeps a running count of all time capsules ever created on this contract.

    event CapsuleCreated(
        // Defines an event that is emitted when a new time capsule is successfully created.
        address indexed owner,
        // The address of the capsule creator, indexed for easier searching in logs.
        uint256 indexed capsuleId,
        // The unique ID (index in the 'capsules' array) of the created capsule, indexed.
        string title,
        // The title of the capsule.
        uint256 unlockTimestamp,
        // The unlock timestamp of the capsule.
        uint256 createdAt
        // The creation timestamp of the capsule.
    );

    event CapsuleOpened(
        // Defines an event that is emitted when a time capsule is successfully opened/viewed.
        address indexed opener,
        // The address of the account that opened (viewed) the capsule, indexed.
        uint256 indexed capsuleId,
        // The ID of the capsule that was opened, indexed.
        address indexed originalOwner
        // The original owner's address of the opened capsule, indexed.
    );

    event CapsuleDeactivated(
        // Defines an event that is emitted when a time capsule is deactivated by its owner.
        address indexed owner,
        // The address of the owner who deactivated the capsule, indexed.
        uint256 indexed capsuleId
        // The ID of the capsule that was deactivated, indexed.
    );

    modifier onlyOwner() {
        // Defines a modifier named 'onlyOwner'. Modifiers are code snippets that can be reused
        // to check conditions before a function's main logic is executed.
        require(msg.sender == owner, "Only contract owner can call this function");
        // Ensures that the address calling the function is the contract's administrative owner.
        // If not, it reverts the transaction with the specified error message.
        _;
        // The '_' symbol tells Solidity to execute the function code where this modifier is applied.
    }

    modifier validCapsule(uint256 _capsuleId) {
        // Defines a modifier named 'validCapsule' to check if a given capsule ID is valid.
        require(_capsuleId < capsules.length, "Capsule does not exist");
        // Ensures that the provided _capsuleId is within the bounds of the 'capsules' array (i.e., it exists).
        require(capsules[_capsuleId].isActive, "Capsule is not active");
        // Ensures that the capsule at the given ID is still active (not deactivated).
        _;
        // Execute the function code.
    }

    modifier onlyCapsuleOwner(uint256 _capsuleId) {
        // Defines a modifier named 'onlyCapsuleOwner' to ensure the caller owns the specific capsule.
        require(capsules[_capsuleId].owner == msg.sender, "Not the capsule owner");
        // Ensures that the address calling the function is the owner of the specified capsule.
        _;
        // Execute the function code.
    }

    constructor() {
        // The constructor is a special function that runs only once when the contract is deployed to the blockchain.
        owner = msg.sender;
        // Sets the deployer of the contract as the administrative owner.
        totalCapsules = 0;
        // Initializes the total number of capsules to zero.
        isPaused = false;
        // Initializes the contract's paused status to false (not paused).
    }

    function createCapsule(
        // Function to allow users to create a new time capsule.
        string memory _dataHash,
        // The cryptographic hash of the off-chain data. 'memory' means it's stored temporarily during execution.
        uint256 _unlockTimestamp,
        // The timestamp when this capsule can be unlocked.
        string memory _title
        // The title of the capsule.
    ) external whenNotPaused returns (uint256) {
        // 'external' means this function can only be called from outside the contract.
        // 'whenNotPaused' modifier ensures the contract is not paused before executing.
        // Returns the ID of the newly created capsule.

        require(bytes(_dataHash).length > 0, "Data hash cannot be empty");
        // Ensures the provided data hash is not an empty string.
        require(_unlockTimestamp > block.timestamp, "Unlock time must be in the future");
        // Ensures the specified unlock timestamp is strictly in the future.
        require(_unlockTimestamp <= block.timestamp + 365 days * 10, "Unlock time too far in the future");
        // Limits the maximum unlock time to 10 years from the current block timestamp.
        require(bytes(_title).length <= 100, "Title too long (max 100 characters)");
        // Limits the length of the title to 100 characters to save gas and storage.

        capsules.push(Capsule({
            // Creates a new 'Capsule' struct and adds it to the 'capsules' array.
            owner: msg.sender,
            // Sets the creator of the capsule as the owner.
            dataHash: _dataHash,
            // Assigns the provided data hash.
            unlockTimestamp: _unlockTimestamp,
            // Assigns the provided unlock timestamp.
            createdAt: block.timestamp,
            // Records the current block timestamp as the creation time.
            title: _title,
            // Assigns the provided title.
            isActive: true
            // Sets the capsule as active by default upon creation.
        }));

        uint256 capsuleId = capsules.length - 1;
        // Gets the ID of the newly created capsule, which is its index in the 'capsules' array.

        userCapsules[msg.sender].push(capsuleId);
        // Adds the new capsule's ID to the list of capsules owned by the caller.
        userCapsuleCount[msg.sender]++;
        // Increments the count of capsules for the caller.
        totalCapsules++;
        // Increments the global count of all capsules.

        emit CapsuleCreated(
            // Emits the 'CapsuleCreated' event to log the details of the new capsule.
            msg.sender,
            capsuleId,
            _title,
            _unlockTimestamp,
            block.timestamp
        );

        return capsuleId;
        // Returns the ID of the newly created capsule.
    }

    function viewCapsule(uint256 _capsuleId)
        // Function to view the content hash and metadata of a capsule once it's unlocked.
        external
        // Only callable from outside the contract.
        whenNotPaused
        // Requires the contract not to be paused.
        validCapsule(_capsuleId)
        // Requires the capsule to exist and be active.
        returns (string memory dataHash, string memory title, address capsuleOwner, uint256 createdAt)
        // Returns the data hash, title, owner, and creation timestamp.
    {
        Capsule memory capsule = capsules[_capsuleId];
        // Retrieves the specific capsule struct from storage into memory for processing.

        require(block.timestamp >= capsule.unlockTimestamp, "Capsule is still locked");
        // Ensures that the current block timestamp is greater than or equal to the capsule's unlock timestamp.
        // If not, it reverts, preventing access to the data hash.

        emit CapsuleOpened(msg.sender, _capsuleId, capsule.owner);
        // Emits the 'CapsuleOpened' event, logging who opened it, which capsule, and its original owner.

        return (
            // Returns the requested capsule details.
            capsule.dataHash,
            capsule.title,
            capsule.owner,
            capsule.createdAt
        );
    }

    function getMyCapsules() external view returns (uint256[] memory) {
        // Returns an array of capsule IDs owned by the caller.
        // 'view' means it doesn't modify the contract's state and is free to call (gas-wise).
        return userCapsules[msg.sender];
        // Retrieves the array of capsule IDs associated with the caller's address.
    }

    function getUserCapsules(address _user) external view returns (uint256[] memory) {
        // Returns an array of capsule IDs owned by a specific user address.
        return userCapsules[_user];
        // Retrieves the array of capsule IDs associated with the provided user address.
    }

    function getCapsuleInfo(uint256 _capsuleId)
        // Function to get general information about a capsule without revealing the dataHash if locked.
        external
        // Only callable from outside the contract.
        view
        // Does not modify state.
        validCapsule(_capsuleId)
        // Requires the capsule to exist and be active.
        returns (
            // Returns various metadata about the capsule.
            address capsuleOwner,
            string memory title,
            uint256 unlockTimestamp,
            uint256 createdAt,
            bool isLocked,
            bool isActive
        )
    {
        Capsule memory capsule = capsules[_capsuleId];
        // Retrieves the capsule data into memory.

        return (
            // Returns the requested details.
            capsule.owner,
            capsule.title,
            capsule.unlockTimestamp,
            capsule.createdAt,
            block.timestamp < capsule.unlockTimestamp, // Calculate if it's currently locked
            // Returns true if the current time is before the unlock timestamp.
            capsule.isActive
            // Returns the active status of the capsule.
        );
    }

    function deactivateCapsule(uint256 _capsuleId)
        // Allows the owner of a capsule to deactivate it before its unlock time.
        external
        // Only callable from outside.
        whenNotPaused
        // Requires the contract not to be paused.
        validCapsule(_capsuleId)
        // Requires the capsule to exist and be active.
        onlyCapsuleOwner(_capsuleId)
        // Requires the caller to be the owner of this specific capsule.
    {
        require(block.timestamp < capsules[_capsuleId].unlockTimestamp, "Capsule already unlocked");
        // Ensures the capsule has not yet reached its unlock timestamp.
        // A capsule cannot be deactivated once it's unlocked.

        capsules[_capsuleId].isActive = false;
        // Sets the 'isActive' flag of the specified capsule to false, deactivating it.

        emit CapsuleDeactivated(msg.sender, _capsuleId);
        // Emits the 'CapsuleDeactivated' event.
    }

    function getTimeUntilUnlock(uint256 _capsuleId)
        // Calculates and returns the time remaining until a capsule is unlocked.
        external
        // Only callable from outside.
        view
        // Does not modify state.
        validCapsule(_capsuleId)
        // Requires the capsule to exist and be active.
        returns (uint256 timeRemaining)
        // Returns the time remaining in seconds.
    {
        if (block.timestamp >= capsules[_capsuleId].unlockTimestamp) {
            // If the current time is past or at the unlock timestamp,
            return 0;
            // Return 0, indicating no time remaining (it's unlocked).
        }
        return capsules[_capsuleId].unlockTimestamp - block.timestamp;
        // Otherwise, return the difference between the unlock time and the current time.
    }

    function getActiveCapsuleCount() external view returns (uint256 count) {
        // Counts and returns the total number of *active* capsules.
        // Note: This function's gas cost increases linearly with the total number of capsules
        // ever created, regardless of active status. This could lead to high gas costs
        // if many capsules are created.
        for (uint256 i = 0; i < capsules.length; i++) {
            // Loops through all capsules in the 'capsules' array.
            if (capsules[i].isActive) {
                // Checks if the current capsule in the loop is active.
                count++;
                // If active, increments the counter.
            }
        }
        return count;
        // Returns the final count of active capsules.
    }

    function getCurrentTime() external view returns (uint256) {
        // Returns the current block's timestamp. Useful for clients to get the blockchain's current time.
        return block.timestamp;
    }

    function dateToTimestamp(
        // Utility function to convert a Gregorian date and time into a Unix timestamp.
        // 'pure' means it doesn't read or modify state.
        uint256 year,
        uint256 month,
        uint256 day,
        uint256 hour,
        uint256 minute
    ) external pure returns (uint256) {
        require(year >= 2024 && year <= 2034, "Year out of reasonable range");
        // Validates the year is within a specific 10-year range (2024-2034).
        require(month >= 1 && month <= 12, "Invalid month");
        // Validates the month is between 1 and 12.
        require(day >= 1 && day <= 31, "Invalid day");
        // Validates the day is between 1 and 31. Note: Does not validate days for specific months (e.g., Feb 30).
        require(hour <= 23, "Invalid hour");
        // Validates the hour is between 0 and 23.
        require(minute <= 59, "Invalid minute");
        // Validates the minute is between 0 and 59.

        uint256 timestamp = 0;
        // Initializes the timestamp calculation.

        for (uint256 y = 1970; y < year; y++) {
            // Loops through years starting from the Unix epoch (1970) up to the target year (exclusive).
            if (isLeapYear(y)) {
                // If it's a leap year, add 366 days.
                timestamp += 366 days;
            } else {
                // Otherwise, add 365 days.
                timestamp += 365 days;
            }
        }

        uint256[12] memory daysInMonth = [
            // Defines an array in memory containing the number of days in each month for a common year.
            uint256(31), uint256(28), uint256(31), uint256(30),
            uint256(31), uint256(30), uint256(31), uint256(31),
            uint256(30), uint256(31), uint256(30), uint256(31)
        ];
        if (isLeapYear(year)) {
            // If the target year is a leap year, adjust February's days to 29.
            daysInMonth[1] = 29;
        }

        for (uint256 m = 1; m < month; m++) {
            // Loops through months from January up to the target month (exclusive).
            timestamp += daysInMonth[m - 1] * 1 days;
            // Adds the number of days in the current month to the timestamp. (m-1 because array is 0-indexed).
        }

        timestamp += (day - 1) * 1 days;
        // Adds days from the current month (day-1 because current day starts from 0 in time units).
        timestamp += hour * 1 hours;
        // Adds the hours.
        timestamp += minute * 1 minutes;
        // Adds the minutes.

        return timestamp;
        // Returns the calculated Unix timestamp.
    }

    function isLeapYear(uint256 year) private pure returns (bool) {
        // Helper function to determine if a given year is a leap year.
        // 'private' means it can only be called from within this contract. 'pure' means it doesn't read or modify state.
        if (year % 4 != 0) return false;
        // If the year is not divisible by 4, it's not a leap year.
        if (year % 100 != 0) return true;
        // If divisible by 4 but not by 100, it's a leap year.
        if (year % 400 != 0) return false;
        // If divisible by 100 but not by 400, it's not a leap year.
        return true;
        // Otherwise (divisible by 400), it's a leap year.
    }

    bool public isPaused;
    // Declares a public boolean state variable to indicate if the contract is paused.

    modifier whenNotPaused() {
        // Defines a modifier that ensures a function can only be called when the contract is NOT paused.
        require(!isPaused, "Contract is paused");
        // Reverts if 'isPaused' is true.
        _;
        // Execute the function code.
    }

    event ContractPaused(address indexed owner);
    // Event emitted when the contract is paused.
    event ContractUnpaused(address indexed owner);
    // Event emitted when the contract is unpaused.

    function emergencyPause() external onlyOwner {
        // Allows the contract owner to pause the contract's functionality in an emergency.
        isPaused = true;
        // Sets the 'isPaused' flag to true.
        emit ContractPaused(msg.sender);
        // Emits the 'ContractPaused' event.
    }

    function unpause() external onlyOwner {
        // Allows the contract owner to unpause the contract's functionality.
        isPaused = false;
        // Sets the 'isPaused' flag to false.
        emit ContractUnpaused(msg.sender);
        // Emits the 'ContractUnpaused' event.
    }
}
