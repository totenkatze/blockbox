// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "Owned.sol";

abstract contract Authorized is Owned {
    mapping(address => bool) private authorizedAddresses;

    event AuthorizationAdded(address indexed _address);
    event AuthorizationRemoved(address indexed _address);

    modifier onlyAuthorized() {
        require(authorizedAddresses[msg.sender], "Authorized: caller is not authorized");
        _;
    }

    constructor() {}

    function isAuthorized(address _address) public view returns (bool) {
        return authorizedAddresses[_address];
    }

    function addAuthorization(address _address) public virtual onlyOwner {
        require(_address != address(0), "Authorized: the supplied address is the zero address");

        authorizedAddresses[_address] = true;

        emit AuthorizationAdded(_address);
    }

    function removeAuthorization(address _address) public virtual onlyOwner {
        delete authorizedAddresses[_address];

        emit AuthorizationRemoved(_address);
    }
}