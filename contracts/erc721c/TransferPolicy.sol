// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

enum AllowlistTypes {
    Operators,
    PermittedContractReceivers
}

enum ReceiverConstraints {
    None,
    NoCode,
    EOA
}

enum CallerConstraints {
    None,
    OperatorWhitelistEnableOTC,
    OperatorWhitelistDisableOTC
}

/**
 * @notice Contains the settings for a token's transfer behavior.
 */
 /*
struct TransferPolicy {
    bool enforceOperatorWhitelist;
    bool disableOTC;
    ReceiverConstraints receiverConstraints;
    address policyOwner;
}
*/

enum TransferSecurityLevels {
    Zero,
    One,
    Two,
    Three,
    Four,
    Five,
    Six
}

struct TransferSecurityPolicy {
    CallerConstraints callerConstraints;
    ReceiverConstraints receiverConstraints;
}

struct CollectionSecurityPolicy {
    TransferSecurityLevels transferSecurityLevel;
    uint120 operatorWhitelistId;
    uint120 permittedContractReceiversId;
}

// Security Level Zero: 
//   - Completely Open Transfers
//
// Security Level One: 
//   - OTC Permitted (Owner Can Initiate A Transfer)
//   - Receiver Address Is Unrestricted
//   - If caller does not own the token, the caller must be whitelisted to transfer the token
//
// Security Level Two: 
//   - OTC Not Permitted 
//   - Receiver Address Is Unrestricted
//   - The caller must be whitelisted to transfer the token
//
// Security Level Three: 
//   - OTC Not Permitted
//   - Receiver Addresses With Code Not Permitted
//   - The caller must be whitelisted to transfer the token
//
// Security Level Four: 
//   - OTC Not Permitted
//   - Receiver Addresses Must Be Verified In EOA Registry
//   - The caller must be whitelisted to transfer the token
