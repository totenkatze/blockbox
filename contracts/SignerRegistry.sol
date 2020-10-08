// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "Owned.sol";

contract SignerRegistry  is Owned {

    event SignerRegistered(address indexed signer, bytes32 indexed domain, int8 percentage);
    event SignerEnabled(address indexed signer);
    event SignerDisabled(address indexed signer);

    struct Signer {
        bytes32 domain;
        address payable paymentAddress;
        int8 percentage;
        bool enabled;
    }

    mapping(address => Signer) private signers;

    function getSigner(address signer) public view returns (bytes32 domain, address payable paymentAddress, int8 percentage, bool enabled) {
        domain = signers[signer].domain;
        paymentAddress = signers[signer].paymentAddress;
        enabled = signers[signer].enabled;
        percentage = signers[signer].percentage;
    }

    function registerSigner(bytes32 domain, address payable paymentAddress, int8 percentage) public returns(bytes32, address payable, int8) {
        require(signers[msg.sender].enabled == false, "SignerRegistry: signer is already registered");
        require(percentage <= 49, "SignerRegistry: percentage must be less than or equal to 49%");

        signers[msg.sender].domain = domain;
        signers[msg.sender].paymentAddress = paymentAddress;
        signers[msg.sender].percentage = percentage;
        signers[msg.sender].enabled = true;

        emit SignerRegistered(msg.sender, domain, percentage);
    }

    function enableSigner(address _address) public onlyOwner {
        signers[_address].enabled = true;

        emit SignerEnabled(msg.sender);
    }

    function disableSigner(address _address) public onlyOwner {
        signers[_address].enabled = false;

        emit SignerDisabled(msg.sender);
    }
}