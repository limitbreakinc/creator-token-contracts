# TransferValidation.sol

**A mix-in that can be used to decompose _beforeTransferToken and _afterTransferToken into granular pre and post mint/burn/transfer validation hooks.  These hooks provide finer grained controls over the lifecycle of an ERC721 token.**

## When To Use This

Open Zeppelin's ERC-721 contracts include a callback function that fires before and after transfers.  However, it is left to the inheriting contract to apply logic to handle the transfer.  Use this contract when you want to more easily control validation logic during mints, burns, or wallet to wallet transfers.  

## Usage

The Transfer Validation mix-in exposes the following hooks that inheriting contracts optionally override depending on the use case.  In most cases, it is advisable to not override the `_validateBeforeTransfer` and `_validateAfterTransfer` functions.  To trigger the hooks, inheriting ERC-721 contracts must call the `_validateBeforeTransfer` and `_validateAfterTransfer` functions from the `_beforeTokenTransfer` and `_afterTokenTransfer` hooks.

```solidity
    /// @dev Optional validation hook that fires before a mint
    function _preValidateMint(address caller, address to, uint256 tokenId, uint256 value) internal virtual {}

    /// @dev Optional validation hook that fires after a mint
    function _postValidateMint(address caller, address to, uint256 tokenId, uint256 value) internal virtual {}

    /// @dev Optional validation hook that fires before a burn
    function _preValidateBurn(address caller, address from, uint256 tokenId, uint256 value) internal virtual {}

    /// @dev Optional validation hook that fires after a burn
    function _postValidateBurn(address caller, address from, uint256 tokenId, uint256 value) internal virtual {}

    /// @dev Optional validation hook that fires before a transfer
    function _preValidateTransfer(address caller, address from, address to, uint256 tokenId, uint256 value) internal virtual {}

    /// @dev Optional validation hook that fires after a transfer
    function _postValidateTransfer(address caller, address from, address to, uint256 tokenId, uint256 value) internal virtual {}
```