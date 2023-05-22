// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "../mocks/minting/SignedApprovalMintMock.sol";
import "../mocks/ClonerMock.sol";
import "./MaxSupply.t.sol";

contract SignedApprovalMintConstructableTest is MaxSupplyTest {
    event SignedClaimsDecommissioned();
    event SignedMintClaimed(address indexed minter, uint256 startTokenId, uint256 endTokenId);
    event SignerUpdated(address oldSigner, address newSigner);

    SignedApprovalMintMock token;
    uint256 signerPkey;
    bytes32 constant EIP712DOMAIN_TYPEHASH =
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
    bytes32 DOMAIN_SEPARATOR;

    function setUp() public {
        signerPkey = uint256(keccak256(abi.encode(uint256(uint160(address(this))))))
            % 0xfffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364141;
        address signer = vm.addr(signerPkey);

        token = new SignedApprovalMintMock(signer, 10000, 10010, 10);
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                EIP712DOMAIN_TYPEHASH,
                keccak256(bytes("SignedApprovalMintMock")),
                keccak256(bytes("1")),
                block.chainid,
                address(token)
            )
        );
    }

    function testAlreadyMinted(address claimer) public {
        vm.assume(claimer != address(0) && claimer.code.length == 0);
        bytes32 sigHash = ECDSA.toTypedDataHash(
            DOMAIN_SEPARATOR, keccak256(abi.encode(keccak256("Approved(address wallet,uint256 quantity)"), claimer, 1))
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerPkey, sigHash);
        bytes memory sig = abi.encodePacked(r, s, v);
        vm.startPrank(claimer);
        vm.expectEmit(true, true, true, true);
        emit SignedMintClaimed(claimer, 1, 1);
        token.claimSignedMint(sig, 1);

        (v, r, s) = vm.sign(signerPkey, sigHash);
        sig = abi.encodePacked(r, s, v);
        vm.expectRevert(SignedApprovalMintBase.SignedApprovalMint__AddressAlreadyMinted.selector);
        token.claimSignedMint(sig, 1);
        vm.stopPrank();
    }

    function testAddrZeroSigner() public {
        vm.expectRevert(SignedApprovalMintBase.SignedApprovalMint__SignerCannotBeInitializedAsAddressZero.selector);
        token = new SignedApprovalMintMock(address(0), 10, 100, 10);
    }

    function testZeroSignedApprovalMints() public {
        vm.expectRevert(SignedApprovalMintBase.SignedApprovalMint__MaxQuantityMustBeGreaterThanZero.selector);
        token = new SignedApprovalMintMock(address(this), 0, 100, 10);
    }

    function testMoreThanMaxSignedMint(uint256 nonce, bytes32 sample) public {
        nonce = bound(nonce, 1, 999999999999999999);
        uint256 amount = 10001;
        address claimer = address(uint160(uint256(keccak256(abi.encodePacked(nonce, sample)))));

        bytes32 sigHash = ECDSA.toTypedDataHash(
            DOMAIN_SEPARATOR,
            keccak256(abi.encode(keccak256("Approved(address wallet,uint256 quantity)"), claimer, amount))
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerPkey, sigHash);
        vm.startPrank(claimer);
        bytes memory sig = abi.encodePacked(r, s, v);
        vm.expectRevert(SignedApprovalMintBase.SignedApprovalMint__MintExceedsMaximumAmountBySignedApproval.selector);
        token.claimSignedMint(sig, amount);
        vm.stopPrank();
    }

    function testInvalidSigner(uint256 invalidSignerKey, uint256 nonce, bytes32 sample) public {
        vm.assume(
            invalidSignerKey > 0
                && invalidSignerKey < 0xfffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364141
        );
        nonce = bound(nonce, 1, 999999999999999999);

        address claimer = address(uint160(uint256(keccak256(abi.encodePacked(nonce, sample)))));
        uint256 amount = 1;

        bytes32 sigHash = ECDSA.toTypedDataHash(
            DOMAIN_SEPARATOR,
            keccak256(abi.encode(keccak256("Approved(address wallet,uint256 quantity)"), claimer, amount))
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(invalidSignerKey, sigHash);
        vm.startPrank(claimer);
        bytes memory sig = abi.encodePacked(r, s, v);
        vm.expectRevert(SignedApprovalMintBase.SignedApprovalMint__InvalidSignature.selector);
        token.claimSignedMint(sig, amount);
        vm.stopPrank();
    }

    function testclaimSignedMint(uint256 nonce, bytes32 sample, uint256 length) public {
        vm.assume(length > 0 && length < 50);
        nonce = bound(nonce, 1, 999999999999999999);
        uint256 amountMinted;
        uint256 maxMintingSupply = token.remainingSignedMints();

        for (uint256 i = 0; i < length; ++i) {
            uint256 amount = i + 1;
            amountMinted += amount;
            address claimer = address(uint160(uint256(keccak256(abi.encodePacked(nonce, sample)))));

            bytes32 sigHash = ECDSA.toTypedDataHash(
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(keccak256("Approved(address wallet,uint256 quantity)"), claimer, amount))
            );

            (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerPkey, sigHash);
            vm.startPrank(claimer);
            bytes memory sig = abi.encodePacked(r, s, v);
            token.claimSignedMint(sig, amount);
            vm.stopPrank();
            assertTrue(token.hasMintedBySignedApproval(claimer));
            ++nonce;
        }
        assertEq(token.remainingSignedMints(), maxMintingSupply - amountMinted);
    }

    function testClaimAfterDecommission(address claimer) public {
        vm.assume(claimer != address(0) && claimer.code.length == 0);

        uint256 maxMintingSupply = token.remainingSignedMints();

        vm.expectEmit(true, true, true, true);
        emit SignedClaimsDecommissioned();
        token.decommissionSignedApprovals();

        assert(token.signedClaimsDecommissioned());

        bytes32 sigHash = ECDSA.toTypedDataHash(
            DOMAIN_SEPARATOR, keccak256(abi.encode(keccak256("Approved(address wallet,uint256 quantity)"), claimer, 1))
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerPkey, sigHash);
        bytes memory sig = abi.encodePacked(r, s, v);
        vm.startPrank(claimer);
        vm.expectRevert(SignedApprovalMintBase.SignedApprovalMint__SignedClaimsAreDecommissioned.selector);
        token.claimSignedMint(sig, 1);
        vm.stopPrank();
        assertEq(token.remainingSignedMints(), maxMintingSupply);
    }

    function testSetSignerAfterDecommission(address signer) public {
        token.decommissionSignedApprovals();

        vm.expectRevert(SignedApprovalMintBase.SignedApprovalMint__SignedClaimsAreDecommissioned.selector);
        token.setSigner(signer);
    }

    function testNewSigner(uint256 newSignerKey, uint256 nonce, bytes32 sample) public {
        vm.assume(newSignerKey > 0 && newSignerKey < 0xfffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364141);
        nonce = bound(nonce, 1, 999999999999999999);

        uint256 maxSignerMints = token.remainingSignedMints();

        address claimer1 = address(uint160(uint256(keccak256(abi.encodePacked(nonce, sample)))));
        address claimer2 = address(uint160(uint256(keccak256(abi.encodePacked(nonce + 1, sample)))));
        uint256 amount = 1;

        bytes32 sigHash = ECDSA.toTypedDataHash(
            DOMAIN_SEPARATOR,
            keccak256(abi.encode(keccak256("Approved(address wallet,uint256 quantity)"), claimer1, amount))
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerPkey, sigHash);
        bytes memory sig = abi.encodePacked(r, s, v);

        vm.startPrank(claimer1);
        token.claimSignedMint(sig, amount);
        vm.stopPrank();

        vm.expectEmit(true, true, true, true);
        emit SignerUpdated(vm.addr(signerPkey), vm.addr(newSignerKey));
        token.setSigner(vm.addr(newSignerKey));

        assertEq(token.approvalSigner(), vm.addr(newSignerKey));

        sigHash = ECDSA.toTypedDataHash(
            DOMAIN_SEPARATOR,
            keccak256(abi.encode(keccak256("Approved(address wallet,uint256 quantity)"), claimer2, amount))
        );
        (v, r, s) = vm.sign(signerPkey, sigHash);
        sig = abi.encodePacked(r, s, v);

        vm.startPrank(claimer2);
        vm.expectRevert(SignedApprovalMintBase.SignedApprovalMint__InvalidSignature.selector);
        token.claimSignedMint(sig, amount);
        vm.stopPrank();

        sigHash = ECDSA.toTypedDataHash(
            DOMAIN_SEPARATOR,
            keccak256(abi.encode(keccak256("Approved(address wallet,uint256 quantity)"), claimer2, amount))
        );
        (v, r, s) = vm.sign(newSignerKey, sigHash);
        sig = abi.encodePacked(r, s, v);

        vm.startPrank(claimer2);
        token.claimSignedMint(sig, amount);
        vm.stopPrank();
        assertEq(token.remainingSignedMints(), maxSignerMints - 2);
    }
}

contract SignedApprovalMintInitializableTest is MaxSupplyInitializableTest {
    event SignedClaimsDecommissioned();
    event SignedMintClaimed(address indexed minter, uint256 startTokenId, uint256 endTokenId);
    event SignerUpdated(address oldSigner, address newSigner);

    SignedApprovalMintInitializableMock token;
    SignedApprovalMintInitializableMock referenceToken;

    uint256 signerPkey;
    bytes32 constant EIP712DOMAIN_TYPEHASH =
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
    bytes32 DOMAIN_SEPARATOR;

    function _deployNewToken(address creator) internal virtual override returns (ITestCreatorMintableToken) {
        address signer = vm.addr(signerPkey);
        referenceToken = new SignedApprovalMintInitializableMock();
        bytes4[] memory initializationSelectors = new bytes4[](3);
        bytes[] memory initializationArguments = new bytes[](3);

        initializationSelectors[0] = referenceToken.initializeERC721.selector;
        initializationArguments[0] = abi.encode("Test", "TST");

        initializationSelectors[1] = referenceToken.initializeSignerAndMaxSignedMintSupply.selector;
        initializationArguments[1] = abi.encode(signer, 10000);

        initializationSelectors[2] = referenceToken.initializeMaxSupply.selector;
        initializationArguments[2] = abi.encode(10010, 10);

        return ITestCreatorMintableToken(
            cloner.cloneContract(address(referenceToken), creator, initializationSelectors, initializationArguments)
        );
    }

    function _deployUninitializedMaxSupply(address creator)
        internal
        virtual
        override
        returns (ITestCreatorMintableToken)
    {
        address signer = vm.addr(signerPkey);
        referenceToken = new SignedApprovalMintInitializableMock();
        bytes4[] memory initializationSelectors = new bytes4[](2);
        bytes[] memory initializationArguments = new bytes[](2);

        initializationSelectors[0] = referenceToken.initializeERC721.selector;
        initializationArguments[0] = abi.encode("Test", "TST");

        initializationSelectors[1] = referenceToken.initializeSignerAndMaxSignedMintSupply.selector;
        initializationArguments[1] = abi.encode(signer, 10000);

        return ITestCreatorMintableToken(
            cloner.cloneContract(address(referenceToken), creator, initializationSelectors, initializationArguments)
        );
    }

    function setUp() public override {
        super.setUp();

        signerPkey = uint256(keccak256(abi.encode(uint256(uint160(address(this))))))
            % 0xfffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364141;
        address signer = vm.addr(signerPkey);
        referenceToken = new SignedApprovalMintInitializableMock();
        bytes4[] memory initializationSelectors = new bytes4[](3);
        bytes[] memory initializationArguments = new bytes[](3);

        initializationSelectors[0] = referenceToken.initializeERC721.selector;
        initializationArguments[0] = abi.encode("Test", "TST");

        initializationSelectors[1] = referenceToken.initializeSignerAndMaxSignedMintSupply.selector;
        initializationArguments[1] = abi.encode(signer, 10000);

        initializationSelectors[2] = referenceToken.initializeMaxSupply.selector;
        initializationArguments[2] = abi.encode(10010, 10);

        token = SignedApprovalMintInitializableMock(
            cloner.cloneContract(
                address(referenceToken), address(this), initializationSelectors, initializationArguments
            )
        );

        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                EIP712DOMAIN_TYPEHASH,
                keccak256(bytes("SignedApprovalMintInitializableMock")),
                keccak256(bytes("1")),
                block.chainid,
                address(token)
            )
        );
    }

    function testInitializeAlreadyInitialized() public {
        vm.expectRevert(
            SignedApprovalMintInitializable.SignedApprovalMintInitializable__SignedMintSupplyAlreadyInitialized.selector
        );
        token.initializeSignerAndMaxSignedMintSupply(address(this), 1000);
    }

    function testAlreadyMinted(address claimer) public {
        vm.assume(claimer != address(0) && claimer.code.length == 0);
        bytes32 sigHash = ECDSA.toTypedDataHash(
            DOMAIN_SEPARATOR, keccak256(abi.encode(keccak256("Approved(address wallet,uint256 quantity)"), claimer, 1))
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerPkey, sigHash);
        bytes memory sig = abi.encodePacked(r, s, v);
        vm.startPrank(claimer);
        vm.expectEmit(true, true, true, true);
        emit SignedMintClaimed(claimer, 1, 1);
        token.claimSignedMint(sig, 1);

        (v, r, s) = vm.sign(signerPkey, sigHash);
        sig = abi.encodePacked(r, s, v);
        vm.expectRevert(SignedApprovalMintBase.SignedApprovalMint__AddressAlreadyMinted.selector);
        token.claimSignedMint(sig, 1);
        vm.stopPrank();
    }

    function testAddrZeroSigner(address claimer) public {
        vm.assume(claimer != address(0) && claimer.code.length == 0);

        bytes4[] memory initializationSelectors = new bytes4[](0);
        bytes[] memory initializationArguments = new bytes[](0);
        token = SignedApprovalMintInitializableMock(
            cloner.cloneContract(
                address(referenceToken), address(this), initializationSelectors, initializationArguments
            )
        );

        bytes32 sigHash = ECDSA.toTypedDataHash(
            DOMAIN_SEPARATOR, keccak256(abi.encode(keccak256("Approved(address wallet,uint256 quantity)"), claimer, 1))
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerPkey, sigHash);
        bytes memory sig = abi.encodePacked(r, s, v);
        vm.startPrank(claimer);
        vm.expectRevert(SignedApprovalMintBase.SignedApprovalMint__SignerIsAddressZero.selector);
        token.claimSignedMint(sig, 1);
        vm.stopPrank();
    }

    function testSetSignerZeroMints() public {
        address signer = vm.addr(signerPkey);

        bytes4[] memory initializationSelectors = new bytes4[](1);
        bytes[] memory initializationArguments = new bytes[](1);

        initializationSelectors[0] = referenceToken.initializeSignerAndMaxSignedMintSupply.selector;
        initializationArguments[0] = abi.encode(signer, 0);
        vm.expectRevert(abi.encodeWithSelector(ClonerMock.InitializationArgumentInvalid.selector, 0));
        token = SignedApprovalMintInitializableMock(
            cloner.cloneContract(
                address(referenceToken), address(this), initializationSelectors, initializationArguments
            )
        );
    }

    function testSetSignerZeroAddress() public {
        bytes4[] memory initializationSelectors = new bytes4[](1);
        bytes[] memory initializationArguments = new bytes[](1);

        initializationSelectors[0] = referenceToken.initializeSignerAndMaxSignedMintSupply.selector;
        initializationArguments[0] = abi.encode(address(0), 10);
        vm.expectRevert(abi.encodeWithSelector(ClonerMock.InitializationArgumentInvalid.selector, 0));
        token = SignedApprovalMintInitializableMock(
            cloner.cloneContract(
                address(referenceToken), address(this), initializationSelectors, initializationArguments
            )
        );
    }

    function testMoreThanMaxSignedMint(uint256 nonce, bytes32 sample) public {
        nonce = bound(nonce, 1, 999999999999999999);
        uint256 amount = 10001;
        address claimer = address(uint160(uint256(keccak256(abi.encodePacked(nonce, sample)))));

        bytes32 sigHash = ECDSA.toTypedDataHash(
            DOMAIN_SEPARATOR,
            keccak256(abi.encode(keccak256("Approved(address wallet,uint256 quantity)"), claimer, amount))
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerPkey, sigHash);
        vm.startPrank(claimer);
        bytes memory sig = abi.encodePacked(r, s, v);
        vm.expectRevert(SignedApprovalMintBase.SignedApprovalMint__MintExceedsMaximumAmountBySignedApproval.selector);
        token.claimSignedMint(sig, amount);
        vm.stopPrank();
    }

    function testInvalidSigner(uint256 invalidSignerKey, uint256 nonce, bytes32 sample) public {
        vm.assume(
            invalidSignerKey > 0
                && invalidSignerKey < 0xfffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364141
        );
        nonce = bound(nonce, 1, 999999999999999999);

        address claimer = address(uint160(uint256(keccak256(abi.encodePacked(nonce, sample)))));
        uint256 amount = 1;

        bytes32 sigHash = ECDSA.toTypedDataHash(
            DOMAIN_SEPARATOR,
            keccak256(abi.encode(keccak256("Approved(address wallet,uint256 quantity)"), claimer, amount))
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(invalidSignerKey, sigHash);
        vm.startPrank(claimer);
        bytes memory sig = abi.encodePacked(r, s, v);
        vm.expectRevert(SignedApprovalMintBase.SignedApprovalMint__InvalidSignature.selector);
        token.claimSignedMint(sig, amount);
        vm.stopPrank();
    }

    function testclaimSignedMint(uint256 nonce, bytes32 sample, uint256 length) public {
        vm.assume(length > 0 && length < 50);
        nonce = bound(nonce, 1, 999999999999999999);
        uint256 amountMinted;
        uint256 maxMintingSupply = token.remainingSignedMints();

        for (uint256 i = 0; i < length; ++i) {
            uint256 amount = i + 1;
            amountMinted += amount;
            address claimer = address(uint160(uint256(keccak256(abi.encodePacked(nonce, sample)))));

            bytes32 sigHash = ECDSA.toTypedDataHash(
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(keccak256("Approved(address wallet,uint256 quantity)"), claimer, amount))
            );

            (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerPkey, sigHash);
            vm.startPrank(claimer);
            bytes memory sig = abi.encodePacked(r, s, v);
            token.claimSignedMint(sig, amount);
            vm.stopPrank();
            assertTrue(token.hasMintedBySignedApproval(claimer));
            ++nonce;
        }
        assertEq(token.remainingSignedMints(), maxMintingSupply - amountMinted);
    }

    function testClaimAfterDecommission(address claimer) public {
        vm.assume(claimer != address(0) && claimer.code.length == 0);

        uint256 maxMintingSupply = token.remainingSignedMints();

        vm.expectEmit(true, true, true, true);
        emit SignedClaimsDecommissioned();
        token.decommissionSignedApprovals();

        assert(token.signedClaimsDecommissioned());

        bytes32 sigHash = ECDSA.toTypedDataHash(
            DOMAIN_SEPARATOR, keccak256(abi.encode(keccak256("Approved(address wallet,uint256 quantity)"), claimer, 1))
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerPkey, sigHash);
        bytes memory sig = abi.encodePacked(r, s, v);
        vm.startPrank(claimer);
        vm.expectRevert(SignedApprovalMintBase.SignedApprovalMint__SignedClaimsAreDecommissioned.selector);
        token.claimSignedMint(sig, 1);
        vm.stopPrank();
        assertEq(token.remainingSignedMints(), maxMintingSupply);
    }

    function testSetSignerAfterDecommission(address signer) public {
        token.decommissionSignedApprovals();

        vm.expectRevert(SignedApprovalMintBase.SignedApprovalMint__SignedClaimsAreDecommissioned.selector);
        token.setSigner(signer);
    }

    function testNewSigner(uint256 newSignerKey, uint256 nonce, bytes32 sample) public {
        vm.assume(newSignerKey > 0 && newSignerKey < 0xfffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364141);
        nonce = bound(nonce, 1, 999999999999999999);

        uint256 maxSignerMints = token.remainingSignedMints();

        address claimer1 = address(uint160(uint256(keccak256(abi.encodePacked(nonce, sample)))));
        address claimer2 = address(uint160(uint256(keccak256(abi.encodePacked(nonce + 1, sample)))));
        uint256 amount = 1;

        bytes32 sigHash = ECDSA.toTypedDataHash(
            DOMAIN_SEPARATOR,
            keccak256(abi.encode(keccak256("Approved(address wallet,uint256 quantity)"), claimer1, amount))
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerPkey, sigHash);
        bytes memory sig = abi.encodePacked(r, s, v);

        vm.startPrank(claimer1);
        token.claimSignedMint(sig, amount);
        vm.stopPrank();

        vm.expectEmit(true, true, true, true);
        emit SignerUpdated(vm.addr(signerPkey), vm.addr(newSignerKey));
        token.setSigner(vm.addr(newSignerKey));

        assertEq(token.approvalSigner(), vm.addr(newSignerKey));

        sigHash = ECDSA.toTypedDataHash(
            DOMAIN_SEPARATOR,
            keccak256(abi.encode(keccak256("Approved(address wallet,uint256 quantity)"), claimer2, amount))
        );
        (v, r, s) = vm.sign(signerPkey, sigHash);
        sig = abi.encodePacked(r, s, v);

        vm.startPrank(claimer2);
        vm.expectRevert(SignedApprovalMintBase.SignedApprovalMint__InvalidSignature.selector);
        token.claimSignedMint(sig, amount);
        vm.stopPrank();

        sigHash = ECDSA.toTypedDataHash(
            DOMAIN_SEPARATOR,
            keccak256(abi.encode(keccak256("Approved(address wallet,uint256 quantity)"), claimer2, amount))
        );
        (v, r, s) = vm.sign(newSignerKey, sigHash);
        sig = abi.encodePacked(r, s, v);

        vm.startPrank(claimer2);
        token.claimSignedMint(sig, amount);
        vm.stopPrank();
        assertEq(token.remainingSignedMints(), maxSignerMints - 2);
    }
}

// TODO: Add to initializable test
// function testAddrZeroSigner(address claimer) public {
//     vm.assume(claimer != address(0) && claimer.code.length == 0);

//     token = new SignedApprovalMintMock(address(0), 10, 100, 10);

//     bytes32 sigHash = ECDSA.toTypedDataHash(
//         DOMAIN_SEPARATOR,
//         keccak256(abi.encode(keccak256("Approved(address wallet,uint256 quantity)"), claimer, 1))
//     );
//     (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerPkey, sigHash);
//     bytes memory sig = abi.encodePacked(r, s, v);
//     vm.startPrank(claimer);
//     vm.expectRevert(SignedApprovalMintBase.SignedApprovalMint__SignerIsAddressZero.selector);
//     token.claimSignedMint(sig, 1);
//     vm.stopPrank();
// }
