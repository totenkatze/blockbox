// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

abstract contract Enabled {
    bool internal enabled;
    
    modifier whenEnabled() {
        require(enabled, "Enabled: this contract is no longer enabled.");
        _;
    }
    
    constructor() {
        enabled = true;
    }

    function isEnabled() public view returns (bool) {
        return enabled;
    }
}