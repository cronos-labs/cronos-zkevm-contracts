// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {IERC6551Registry} from "./IERC6551Registry.sol";
import {ZksyncCreate2} from "./ZksyncCreate2.sol";
import {AccountProxy} from "./AccountProxy.sol";

// `ACCOUNT_PROXY_BYTECODE_HASH` need to be updated whenever the `AccountProxy.sol` contract changed.
bytes32 constant ACCOUNT_PROXY_BYTECODE_HASH = bytes32(
    0x0100003d562de1d8af655bd7c866b6a2e4a08c854a2298169333325033a9d480
);

contract ERC6551Registry is IERC6551Registry {
    function getConstructorInput(
        address implementation,
        bytes32 salt,
        uint256 chainId,
        address tokenContract,
        uint256 tokenId
    ) internal pure returns (bytes memory) {
        return
            abi.encode(implementation, salt, chainId, tokenContract, tokenId);
    }

    function getProxyAccountBytecode(
        address implementation,
        bytes32 salt,
        uint256 chainId,
        address tokenContract,
        uint256 tokenId
    ) internal pure returns (bytes memory) {
        bytes memory bytecode = type(AccountProxy).creationCode;

        return
            abi.encodePacked(
                bytecode,
                getConstructorInput(
                    implementation,
                    salt,
                    chainId,
                    tokenContract,
                    tokenId
                )
            );
    }

    function createAccount(
        address implementation,
        bytes32 salt,
        uint256 chainId,
        address tokenContract,
        uint256 tokenId
    ) external returns (address) {
        address _account = _computeAccountAddress(
            implementation,
            salt,
            chainId,
            tokenContract,
            tokenId
        );

        // The account has already been created, return it directly
        if (_account.code.length != 0) return _account;

        bytes memory bytecode = getProxyAccountBytecode(
            implementation,
            salt,
            chainId,
            tokenContract,
            tokenId
        );

        assembly {
            _account := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }

        if (_account.code.length == 0) {
            revert AccountCreationFailed();
        }

        emit ERC6551AccountCreated(
            _account,
            implementation,
            salt,
            chainId,
            tokenContract,
            tokenId
        );

        return _account;
    }

    function _computeAccountAddress(
        address implementation,
        bytes32 salt,
        uint256 chainId,
        address tokenContract,
        uint256 tokenId
    ) internal view returns (address) {
        return
            ZksyncCreate2.getNewAddressCreate2(
                address(this),
                ACCOUNT_PROXY_BYTECODE_HASH,
                salt,
                keccak256(
                    getConstructorInput(
                        implementation,
                        salt,
                        chainId,
                        tokenContract,
                        tokenId
                    )
                )
            );
    }

    function account(
        address implementation,
        bytes32 salt,
        uint256 chainId,
        address tokenContract,
        uint256 tokenId
    ) external view returns (address) {
        return
            _computeAccountAddress(
                implementation,
                salt,
                chainId,
                tokenContract,
                tokenId
            );
    }
}
