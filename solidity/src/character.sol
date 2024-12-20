// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract WoWCharacterNFT is ERC721 {
    uint256 private _tokenIds;

    address public owner;

    struct CharacterData {
        string name;
        uint256 level;
        uint256 class;
        uint256 race;
        uint256 mapId;
        uint256 zoneId;
        uint256 areaId;
        int256 x;
        int256 y;
        int256 z;
        string inventoryJson;
        string reputationJson;
        string achievementsJson;
        string arenaStatsJson;
        string glyphsJson;
        string homebindJson;
        string questStatusesJson;
        string skillsJson;
        string spellsJson;
    }

    struct CharacterUpdateData {
        uint256 level;
        uint256 mapId;
        uint256 zoneId;
        uint256 areaId;
        int256 x;
        int256 y;
        int256 z;
        string inventoryJson;
        string reputationJson;
        string achievementsJson;
        string arenaStatsJson;
        string glyphsJson;
        string homebindJson;
        string questStatusesJson;
        string skillsJson;
        string spellsJson;
    }

    mapping(uint256 => CharacterData) public characters;
    mapping(address => uint256) public playerTokenIds;

    event CharacterMinted(uint256 indexed tokenId, address indexed owner, string name);
    event CharacterUpdated(uint256 indexed tokenId, string name);

    constructor() ERC721("WoW Character NFT", "WOWCHAR") {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    function mintCharacter(
        address playerAddress,
        string memory name,
        uint256 level,
        uint256 class,
        uint256 race,
        uint256 mapId,
        uint256 zoneId,
        uint256 areaId,
        int256 x,
        int256 y,
        int256 z
    ) public onlyOwner returns (uint256) {
        require(playerTokenIds[playerAddress] == 0, "Player already has a character NFT");
        
        _tokenIds++;
        uint256 newTokenId = _tokenIds;

        _safeMint(playerAddress, newTokenId);
        playerTokenIds[playerAddress] = newTokenId;

        characters[newTokenId] = CharacterData({
            name: name,
            level: level,
            class: class,
            race: race,
            mapId: mapId,
            zoneId: zoneId,
            areaId: areaId,
            x: x,
            y: y,
            z: z,
            inventoryJson: "",
            reputationJson: "",
            achievementsJson: "",
            arenaStatsJson: "",
            glyphsJson: "",
            homebindJson: "",
            questStatusesJson: "",
            skillsJson: "",
            spellsJson: ""
        });

        emit CharacterMinted(newTokenId, playerAddress, name);

        return newTokenId;
    }

    function updateCharacter(uint256 tokenId, CharacterUpdateData memory updateData) public onlyOwner {
        require(_exists(tokenId), "Character does not exist");
        require(bytes(updateData.inventoryJson).length > 0, "Inventory JSON cannot be empty");
        require(bytes(updateData.reputationJson).length > 0, "Reputation JSON cannot be empty");
        // Add more require statements for other fields if needed

        CharacterData storage character = characters[tokenId];

        character.level = updateData.level;
        character.mapId = updateData.mapId;
        character.zoneId = updateData.zoneId;
        character.areaId = updateData.areaId;
        character.x = updateData.x;
        character.y = updateData.y;
        character.z = updateData.z;
        character.inventoryJson = updateData.inventoryJson;
        character.reputationJson = updateData.reputationJson;
        character.achievementsJson = updateData.achievementsJson;
        character.arenaStatsJson = updateData.arenaStatsJson;
        character.glyphsJson = updateData.glyphsJson;
        character.homebindJson = updateData.homebindJson;
        character.questStatusesJson = updateData.questStatusesJson;
        character.skillsJson = updateData.skillsJson;
        character.spellsJson = updateData.spellsJson;

        emit CharacterUpdated(tokenId, character.name);
    }

    function getCharacterData(uint256 tokenId) public view returns (CharacterData memory) {
        require(_exists(tokenId), "Character does not exist");
        return characters[tokenId];
    }

    function getOwner() external view returns (address) {
        return owner;
    }

    function _exists(uint256 tokenId) internal view virtual override returns (bool) {
        return _ownerOf(tokenId) != address(0);
    }

    function getPlayerTokenId(address playerAddress) public view returns (uint256) {
        return playerTokenIds[playerAddress];
    }
}
