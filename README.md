Time Capsule Smart Contract

This Solidity smart contract enables users to create and manage digital time capsules on the Ethereum blockchain. It allows you to commit a hash of off-chain data (like a file on IPFS) along with a future unlock timestamp and a title. The actual content of your capsule is never stored on the blockchain, only its cryptographic hash, ensuring privacy and reducing on-chain storage costs.



Features

•	Create Time Capsules: Users can create new capsules by providing a data hash (e.g., an IPFS CID), a future unlock timestamp, and a title.

•	Off-Chain Data Storage: Only the hash of your data is stored on-chain. This keeps your actual sensitive information private until the unlock time and significantly reduces transaction costs.

•	Time-Locked Access: Capsules can only be opened (their dataHash revealed) once their specified unlockTimestamp has passed.

•	Owner-Specific Capsules: Each capsule is owned by the address that created it.

•	Capsule Deactivation: Owners can deactivate their capsules before the unlock timestamp. Deactivated capsules cannot be opened.


•	Information Retrieval:

o	Retrieve all capsule IDs owned by msg.sender (getMyCapsules).

o	Retrieve all capsule IDs owned by any specific user address (getUserCapsules).

o	Get public metadata about any capsule (owner, title, unlock time, creation time, locked status, active status) without revealing the dataHash if it's still locked (getCapsuleInfo).

•	Time Utilities: Includes a dateToTimestamp utility function to convert a Gregorian date and time into a Unix timestamp (supports years from 2024 to 2034) and getCurrentTime to get the blockchain's current timestamp.

•	Administrative Pause: The contract owner can emergencyPause() and unpause() the contract, halting functions like createCapsule and viewCapsule in emergencies.

•	Event Logging: Key actions like capsule creation, opening, deactivation, and contract pausing/unpausing are logged as events for easy monitoring and off-chain indexing.



How It Works

1.	Creation: A user calls createCapsule() providing a hash of their data (which they've stored elsewhere, like IPFS), a title, and a timestamp in the future when the capsule can be opened. The contract stores this information and assigns a unique capsuleId.

2.	Waiting Period: The capsule remains "locked" until the unlockTimestamp is reached.

3.	Opening: Once block.timestamp is greater than or equal to the unlockTimestamp, anyone can call viewCapsule() with the capsuleId to retrieve the dataHash (and other public metadata). The user can then use this dataHash to retrieve the actual content from the off-chain storage.

4.	Deactivation: An owner can call deactivateCapsule() on their own capsule, provided it hasn't been unlocked yet. This prevents anyone from viewing its dataHash in the future.
Contract Details

•	License: MIT

•	Solidity Version: ^0.8.20



Contract Functions (Key Interactions)

Core User Functions:

•	createCapsule(string memory _dataHash, uint256 _unlockTimestamp, string memory _title): Creates a new time capsule. Returns the capsuleId.

•	viewCapsule(uint256 _capsuleId): Retrieves the dataHash and other details for an unlocked capsule.

•	deactivateCapsule(uint256 _capsuleId): Marks a capsule as inactive, preventing it from being opened in the future (must be called by the owner before unlock).

Information & Utility Functions (View/Read-Only):

•	capsules(uint256): Public getter for a Capsule struct by its ID.

•	userCapsuleCount(address): Returns the count of active capsules for a given user.

•	owner(): Returns the contract's administrative owner.

•	totalCapsules(): Returns the total number of capsules ever created.

•	isPaused(): Checks if the contract is currently paused.

•	getMyCapsules(): Returns an array of capsule IDs owned by the caller.

•	getUserCapsules(address _user): Returns an array of capsule IDs for a specified user.

•	getCapsuleInfo(uint256 _capsuleId): Provides metadata about a capsule without revealing the dataHash if locked.

•	getTimeUntilUnlock(uint256 _capsuleId): Returns seconds remaining until a capsule unlocks.

•	getActiveCapsuleCount(): Returns the total count of currently active capsules.

•	getCurrentTime(): Returns the current blockchain timestamp.

•	dateToTimestamp(uint256 year, uint256 month, uint256 day, uint256 hour, uint256 minute): Converts a date/time to a Unix timestamp.



Administrative Functions (Owner Only):

•	emergencyPause(): Pauses core contract functionality.

•	unpause(): Unpauses the contract.
