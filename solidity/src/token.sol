// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract WowToken is ERC20Votes, Ownable {
    uint256 public constant TAX_RATE = 5; // 5% tax
    uint256 public constant OWNERSHIP_DURATION = 1 days;

    struct MapOwnership {
        address owner;
        uint256 expirationTime;
    }

    mapping(uint256 => MapOwnership) public mapOwners;

    event MapPurchased(uint256 indexed mapId, address indexed newOwner);
    event TaxPaid(uint256 indexed mapId, address indexed mapOwner, uint256 amount);

    constructor() 
        ERC20("WowToken", "WOW") 
        ERC20Permit("WowToken")
        Ownable()
    {
        _mint(msg.sender, 1000000 * 10**decimals()); // Mint initial supply to deployer
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mintInternal(to, amount, 0);
    }

    function mint(address to, uint256 amount, uint256 mapId) public onlyOwner {
        _mintInternal(to, amount, mapId);
    }

    function _mintInternal(address to, uint256 amount, uint256 mapId) private {
        uint256 taxAmount = (amount * TAX_RATE) / 100;
        uint256 netAmount = amount - taxAmount;

        _mint(to, netAmount);

        if (mapId != 0 && mapOwners[mapId].owner != address(0) && mapOwners[mapId].expirationTime > block.timestamp) {
            _mint(mapOwners[mapId].owner, taxAmount);
            emit TaxPaid(mapId, mapOwners[mapId].owner, taxAmount);
        } else {
            _mint(owner(), taxAmount);
        }
    }

    function burn(address from, uint256 amount) external onlyOwner {
        _burnInternal(from, amount, 0);
    }

    function burn(address from, uint256 amount, uint256 mapId) external onlyOwner {
        _burnInternal(from, amount, mapId);
    }

    function _burnInternal(address from, uint256 amount, uint256 mapId) private {
        uint256 taxAmount = (amount * TAX_RATE) / 100;
        uint256 netAmount = amount - taxAmount;

        _burn(from, netAmount);

        if (mapId != 0 && mapOwners[mapId].owner != address(0) && mapOwners[mapId].expirationTime > block.timestamp) {
            _mint(mapOwners[mapId].owner, taxAmount);
            emit TaxPaid(mapId, mapOwners[mapId].owner, taxAmount);
        } else {
            _mint(owner(), taxAmount);
        }
    }

    function purchaseMap(uint256 mapId) external {
        require(balanceOf(msg.sender) >= 10000, "Insufficient balance to purchase map");
        require(mapOwners[mapId].expirationTime < block.timestamp, "Map is already owned");

        _burn(msg.sender, 10000);
        mapOwners[mapId] = MapOwnership(msg.sender, block.timestamp + OWNERSHIP_DURATION);

        emit MapPurchased(mapId, msg.sender);
    }

    function getMapOwner(uint256 mapId) external view returns (address) {
        if (mapOwners[mapId].expirationTime > block.timestamp) {
            return mapOwners[mapId].owner;
        }
        return address(0);
    }

    // The following functions are overrides required by Solidity.

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._afterTokenTransfer(from, to, amount);
    }

    function _mint(
        address to,
        uint256 amount
    ) internal virtual override {
        super._mint(to, amount);
    }

    function _burn(
        address account,
        uint256 amount
    ) internal virtual override {
        super._burn(account, amount);
    }
}
