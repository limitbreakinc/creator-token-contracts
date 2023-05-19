// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

contract ContractMock is ERC1155Holder {
    constructor() {}

    fallback() external payable {}
    receive() external payable {}

    function foo() external pure returns (string memory) {
        return "foo";
    }

    function bar() external pure returns (string memory) {
        return "bar";
    }
}
