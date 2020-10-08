// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "Authorized.sol";

contract LockboxRegistry is Authorized {
    
    event LockboxCreated(address indexed signerAddress, bytes16 indexed id, address sellerAddress, uint256 price, uint256 minBidStep, uint256 endBlock);
    event LockboxUpdated(address indexed signerAddress, bytes16 indexed id, bytes16 indexed currentBidderId, address currentBidderAddress, uint256 price);
    event LockboxDeleted(address indexed signerAddress, bytes16 indexed id);
    event LockboxSold (address indexed signerAddress, bytes16 indexed id, bytes16 indexed bidderId, uint256 price);
    
    struct Lockbox {
        address payable sellerAddress;
        address payable currentBidderAddress;
        uint256 price;
        uint256 minBidStep;
        uint256 endBlock;
        bytes16 currentBidderId;
    }
    
    mapping(address => mapping(bytes16 => Lockbox)) private lockboxes;
    
    function createLockbox(address signerAddress, bytes16 id, address payable sellerAddress, uint256 price, uint256 minBidStep, uint256 endBlock) public onlyAuthorized {
        require(lockboxes[signerAddress][id].sellerAddress == address(0), "LockboxRegistry: the lockbox already exists");
        
        lockboxes[signerAddress][id].sellerAddress = sellerAddress;
        lockboxes[signerAddress][id].price = price;
        lockboxes[signerAddress][id].minBidStep = minBidStep;
        lockboxes[signerAddress][id].endBlock = endBlock;
        
        emit LockboxCreated(signerAddress, id, sellerAddress, price, minBidStep, endBlock);
    }
    
    function retrieveLockbox(address signerAddress, bytes16 id) public view returns (address payable sellerAddress, address payable currentBidderAddress, uint256 price, uint256 minBidStep, uint256 endBlock, bytes16 currentBidderId) {
        sellerAddress = lockboxes[signerAddress][id].sellerAddress;
        currentBidderAddress = lockboxes[signerAddress][id].currentBidderAddress;
        price = lockboxes[signerAddress][id].price;
        minBidStep = lockboxes[signerAddress][id].minBidStep;
        endBlock = lockboxes[signerAddress][id].endBlock;
        currentBidderId = lockboxes[signerAddress][id].currentBidderId;
    }
    
    function updateLockbox(address signerAddress, bytes16 id, address payable currentBidderAddress, uint256 price, bytes16 currentBidderId) public onlyAuthorized {
        lockboxes[signerAddress][id].currentBidderAddress = currentBidderAddress;
        lockboxes[signerAddress][id].price = price;
        lockboxes[signerAddress][id].currentBidderId = currentBidderId;
        
        emit LockboxUpdated(signerAddress, id, currentBidderId, currentBidderAddress, price);
    }
    
    function deleteLockbox(address signerAddress, bytes16 id) public onlyAuthorized {
        delete lockboxes[signerAddress][id];
        
        emit LockboxDeleted(signerAddress, id);
    }
    
    function emitLockboxSold(address signerAddress, bytes16 id, bytes16 bidderId, uint256 price) public onlyAuthorized {
        emit LockboxSold(signerAddress, id, bidderId, price);
    }
}