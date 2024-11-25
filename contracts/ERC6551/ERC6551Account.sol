// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC1271} from "@openzeppelin/contracts/interfaces/IERC1271.sol";
import {SignatureChecker} from "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";

import {IERC6551Account} from "./IERC6551Account.sol";
import {IERC6551Executable} from "./IERC6551Executable.sol";
import {IImmutableSimulator, IMMUTABLE_SIMULATOR_ADDRESS} from "./IImmutableSimulator.sol";

contract ERC6551Account is
    IERC165,
    IERC1271,
    IERC6551Account,
    IERC6551Executable
{
    uint256 public state;

    receive() external payable {}

    function execute(
        address to,
        uint256 value,
        bytes calldata data,
        uint8 operation
    ) external payable returns (bytes memory result) {
        require(
            isValidSigner(msg.sender, data) ==
                IERC6551Account.isValidSigner.selector,
            "Invalid signer"
        );
        require(operation == 0, "Only call operations are supported");

        ++state;

        bool success;
        (success, result) = to.call{value: value}(data);

        if (!success) {
            assembly {
                revert(add(result, 32), mload(result))
            }
        }
    }

    function isValidSignature(
        bytes32 hash,
        bytes memory signature
    ) external view returns (bytes4 magicValue) {
        bool isValid = SignatureChecker.isValidSignatureNow(
            owner(),
            hash,
            signature
        );

        if (isValid) {
            return IERC1271.isValidSignature.selector;
        }

        return bytes4(0);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) external pure returns (bool) {
        return (interfaceId == type(IERC165).interfaceId ||
            interfaceId == type(IERC6551Account).interfaceId ||
            interfaceId == type(IERC6551Executable).interfaceId);
    }

    /**
     * Please read the docs of AccountProxy.sol for more information.
     */
    function token() public view returns (uint256, address, uint256) {
        address _this = address(this);
        IImmutableSimulator immutableSimulator = IImmutableSimulator(
            IMMUTABLE_SIMULATOR_ADDRESS
        );
        bytes32 chainId = immutableSimulator.getImmutable(_this, 2 * 0x20);
        bytes32 tokenContract = immutableSimulator.getImmutable(
            _this,
            3 * 0x20
        );
        bytes32 tokenId = immutableSimulator.getImmutable(_this, 4 * 0x20);

        return (
            uint256(chainId),
            address(uint160(uint256(tokenContract))),
            uint256(tokenId)
        );
    }

    function owner() public view returns (address) {
        (uint256 chainId, address tokenContract, uint256 tokenId) = token();
        if (chainId != block.chainid) return address(0);

        return IERC721(tokenContract).ownerOf(tokenId);
    }

    function isValidSigner(
        address signer,
        bytes calldata
    ) public view returns (bytes4 magicValue) {
        if (signer == owner()) {
            return IERC6551Account.isValidSigner.selector;
        }

        return bytes4(0);
    }
}
