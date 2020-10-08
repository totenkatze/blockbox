// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "Owned.sol";
import "SignerRegistry.sol";
import "LockboxRegistry.sol";
import "SafeMath.sol";
import "SafeTransfer.sol";

contract LockboxAuction is Owned {
    using SafeMath for uint256;
    using SafeTransfer for address payable;

    address payable private feePaymentAddress;
    address private signerRegistryAddress;
    address private lockboxRegistryAddress;

    constructor(address payable _feePaymentAddress, address _signerRegistryAddress, address _lockboxRegistryAddress) {
        feePaymentAddress = _feePaymentAddress;
        signerRegistryAddress = _signerRegistryAddress;
        lockboxRegistryAddress = _lockboxRegistryAddress;
    }

    function getSigner(address signerAddress) public view returns (bytes32 domain, address payable paymentAddress, int8 percentage, bool enabled) {
        (domain, paymentAddress, percentage, enabled) = SignerRegistry(signerRegistryAddress).getSigner(signerAddress);
    }

    function getLockbox(address signerAddress, bytes16 id) public view returns (address payable sellerAddress, address payable currentBidderAddress, uint256 price, uint256 minBidStep, uint256 endBlock, bytes16 currentBidderId) {
        (sellerAddress, currentBidderAddress, price, minBidStep, endBlock, currentBidderId) = LockboxRegistry(lockboxRegistryAddress).retrieveLockbox(signerAddress, id);
    }

    function checkLockboxOwnerKey(uint8 v, bytes32 r, bytes32 s, bytes16 id) public view returns (address signerAddress, bool valid) {
        bytes32 messageHash = keccak256(abi.encodePacked(id));

        signerAddress = ecrecover(messageHash, v, r, s);
        (,,,valid) = getSigner(signerAddress);
    }

    function checkLockboxBidderKey(uint8 v, bytes32 r, bytes32 s, bytes16 id, bytes16 bidderId) public view returns (address signerAddress, bool valid) {
        bytes32 messageHash = keccak256(abi.encodePacked(id, bidderId));

        signerAddress = ecrecover(messageHash, v, r, s);

        (,,,valid) = getSigner(signerAddress);
    }

    function createLockbox(uint8 v, bytes32 r, bytes32 s, bytes16 id, uint256 price, uint256 minBidStep, uint256 blockDuration) public {
        require(price > 0, "LockboxAuction: price must be greater than zero");

        address signerAddress = ecrecover(keccak256(abi.encodePacked(id)), v, r, s);
        (,,, bool signerEnabled) = getSigner(signerAddress);

        require(signerEnabled, "LockboxAuction: the lockbox key was not signed by a valid signer");

        uint256 endBlock = blockDuration > 0 ? block.number.add(blockDuration) : 0;

        LockboxRegistry(lockboxRegistryAddress).createLockbox(signerAddress, id, payable(msg.sender), price, minBidStep, endBlock);
    }

    function deleteLockbox(uint8 v, bytes32 r, bytes32 s, bytes16 id) public {
        address signerAddress = ecrecover(keccak256(abi.encodePacked(id)), v, r, s);
        (,,, bool signerEnabled) = getSigner(signerAddress);
        (address sellerAddress, address currentBidderAddress,, uint256 endBlock,,) = getLockbox(signerAddress, id);

        require(signerEnabled, "LockboxAuction: the lockbox key was not signed by a valid signer");
        require(sellerAddress == msg.sender, "LockboxAuction: you cannot delete a lockbox belonging to another owner");
        require(endBlock == 0 || (block.number < endBlock && currentBidderAddress == address(0)), "LockboxAuction: the lockbox cannot be deleted");

        LockboxRegistry(lockboxRegistryAddress).deleteLockbox(signerAddress, id);
    }

    function bidOnLockbox(uint8 v, bytes32 r, bytes32 s, bytes16 id, bytes16 bidderId) public payable {
        address signerAddress = ecrecover(keccak256(abi.encodePacked(id, bidderId)), v, r, s);
        (,,, bool signerEnabled) = getSigner(signerAddress);
        (, address payable currentBidderAddress, uint256 price, uint256 minBidStep, uint256 endBlock,) = getLockbox(signerAddress, id);

        require(signerEnabled, "LockboxAuction: the lockbox key was not signed by a valid signer");
        require((currentBidderAddress == address(0) && price <= msg.value) || price.add(minBidStep) < msg.value, "LockboxAuction: an insufficient amount of eth was sent");
        require(endBlock == 0 || block.number < endBlock, "LockboxAuction: the lockbox auction is over");

        LockboxRegistry(lockboxRegistryAddress).updateLockbox(signerAddress, id, msg.sender, msg.value, bidderId);

        // Refund the previous bidder.
        if (currentBidderAddress != address(0)) {
            currentBidderAddress.safeTransfer(price);
        }

        // If this is an instant sale (or if we are on the last block before the end of the auction) proceed to finalize.
        if (endBlock == 0 || endBlock.sub(block.number) == 1) {
            finalizeLockbox(signerAddress, id);
        }
    }

    function finalizeLockbox(address signerAddress, bytes16 id) public {
        (, address payable signerPaymentAddress, int8 signerPercentage, bool signerEnabled) = getSigner(signerAddress);
        (address payable sellerAddress, address payable currentBidderAddress, uint256 price,, uint256 endBlock, bytes16 currentBidderId) = getLockbox(signerAddress, id);

        require(signerEnabled, "LockboxAuction: the lockbox key was not signed by a valid signer");
        require(currentBidderAddress != address(0), "LockboxAuction: lockbox has no buyer");
        require(endBlock == 0 || endBlock <= block.number, "LockboxAuction: the lockbox auction is not over");

        uint256 fee = price.div(100);

        feePaymentAddress.safeTransfer(fee);

        uint256 commission = price.mul(uint256(signerPercentage)).div(100);

        signerPaymentAddress.safeTransfer(commission);

        sellerAddress.safeTransfer(price.sub(fee).sub(commission));

        LockboxRegistry(lockboxRegistryAddress).deleteLockbox(signerAddress, id);

        LockboxRegistry(lockboxRegistryAddress).emitLockboxSold(signerAddress, id, currentBidderId, price);
    }
    
    function getFeePaymentAddress() public view returns (address) {
        return feePaymentAddress;   
    }
    
    function getSignerRegistrytAddress() public view returns (address) {
        return signerRegistryAddress;   
    }
    
    function getLockboxRegistrytAddress() public view returns (address) {
        return lockboxRegistryAddress;   
    }
    
    function setFeePaymentAddress(address payable _feePaymentAddress) public onlyOwner {
        require(_feePaymentAddress != address(0), "LockboxAuction: new fee payment address is the zero address");

        feePaymentAddress = _feePaymentAddress;
    }

    function setSignerRegistrytAddress(address _signerRegistryAddress) public onlyOwner {
        require(_signerRegistryAddress != address(0), "LockboxAuction: new signer registry address is the zero address");

        signerRegistryAddress = _signerRegistryAddress;
    }

    function setLockboxRegistryAddress(address _lockboxRegistryAddress) public onlyOwner {
        require(_lockboxRegistryAddress != address(0), "LockboxAuction: new lockbox registry address is the zero address");

        lockboxRegistryAddress = _lockboxRegistryAddress;
    }
}