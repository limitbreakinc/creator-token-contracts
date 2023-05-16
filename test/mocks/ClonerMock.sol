// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "test/interfaces/IOwnableInitializable.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";

contract ClonerMock {

    error InitializationArgumentInvalid(uint256 arrayIndex);

    constructor() {}

    function cloneContract(
        address referenceContract,
        address contractOwner,
        bytes4[] calldata initializationSelectors,
        bytes[] calldata initializationArgs
    ) external returns (address) {
        address clone = Clones.clone(referenceContract);

        IOwnableInitializer(clone).initializeOwner(address(this));

        for (uint256 i = 0; i < initializationSelectors.length;) {
            (bool success,) = clone.call(abi.encodePacked(initializationSelectors[i], initializationArgs[i]));

            if (!success) {
                revert InitializationArgumentInvalid(i);
            }

            unchecked {
                ++i;
            }
        }

        IOwnableInitializer(clone).transferOwnership(contractOwner);

        return clone;
    }
}
