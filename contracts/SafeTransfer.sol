// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

library SafeTransfer {
    function safeTransfer(address payable _address, uint256 amount) internal {
        (bool success, ) = _address.call{value:amount}("");
        require(success, "Transfer failed.");
    }
}