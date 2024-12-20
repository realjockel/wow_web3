from web3 import Web3

w3 = Web3(Web3.HTTPProvider("http://localhost:8545"))

contract_address = "0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512"
# Updated ABI to include new functions and events
wowToken_abi = [
    {
        "inputs": [
            {"internalType": "address", "name": "to", "type": "address"},
            {"internalType": "uint256", "name": "amount", "type": "uint256"}
        ],
        "name": "mint",
        "outputs": [],
        "stateMutability": "nonpayable",
        "type": "function"
    },
    {
        "inputs": [
            {"internalType": "address", "name": "to", "type": "address"},
            {"internalType": "uint256", "name": "amount", "type": "uint256"},
            {"internalType": "uint256", "name": "mapId", "type": "uint256"}
        ],
        "name": "mint",
        "outputs": [],
        "stateMutability": "nonpayable",
        "type": "function"
    },
    {
        "inputs": [
            {"internalType": "address", "name": "from", "type": "address"},
            {"internalType": "uint256", "name": "amount", "type": "uint256"}
        ],
        "name": "burn",
        "outputs": [],
        "stateMutability": "nonpayable",
        "type": "function"
    },
    {
        "inputs": [
            {"internalType": "address", "name": "from", "type": "address"},
            {"internalType": "uint256", "name": "amount", "type": "uint256"},
            {"internalType": "uint256", "name": "mapId", "type": "uint256"}
        ],
        "name": "burn",
        "outputs": [],
        "stateMutability": "nonpayable",
        "type": "function"
    },
    {
        "inputs": [{"internalType": "uint256", "name": "mapId", "type": "uint256"}],
        "name": "purchaseMap",
        "outputs": [],
        "stateMutability": "nonpayable",
        "type": "function"
    },
    {
        "inputs": [{"internalType": "uint256", "name": "mapId", "type": "uint256"}],
        "name": "getMapOwner",
        "outputs": [{"internalType": "address", "name": "", "type": "address"}],
        "stateMutability": "view",
        "type": "function"
    },
    {
        "inputs": [],
        "name": "getOwner",
        "outputs": [{"internalType": "address", "name": "", "type": "address"}],
        "stateMutability": "view",
        "type": "function"
    },
    {
        "inputs": [{"internalType": "address", "name": "account", "type": "address"}],
        "name": "balanceOf",
        "outputs": [{"internalType": "uint256", "name": "", "type": "uint256"}],
        "stateMutability": "view",
        "type": "function"
    }
]

# Updated ABI to include new functions for the WoWCharacterNFT contract
wowCharacterNFT_abi = [
    {
        "inputs": [
            {"internalType": "address", "name": "playerAddress", "type": "address"},
            {"internalType": "string", "name": "name", "type": "string"},
            {"internalType": "uint256", "name": "level", "type": "uint256"},
            {"internalType": "uint256", "name": "class", "type": "uint256"},
            {"internalType": "uint256", "name": "race", "type": "uint256"},
            {"internalType": "uint256", "name": "mapId", "type": "uint256"},
            {"internalType": "uint256", "name": "zoneId", "type": "uint256"},
            {"internalType": "uint256", "name": "areaId", "type": "uint256"},
            {"internalType": "int256", "name": "x", "type": "int256"},
            {"internalType": "int256", "name": "y", "type": "int256"},
            {"internalType": "int256", "name": "z", "type": "int256"}
        ],
        "name": "mintCharacter",
        "outputs": [{"internalType": "uint256", "name": "", "type": "uint256"}],
        "stateMutability": "nonpayable",
        "type": "function"
    },
    {
        "inputs": [
            {"internalType": "uint256", "name": "tokenId", "type": "uint256"},
            {"internalType": "uint256", "name": "level", "type": "uint256"},
            {"internalType": "uint256", "name": "mapId", "type": "uint256"},
            {"internalType": "uint256", "name": "zoneId", "type": "uint256"},
            {"internalType": "uint256", "name": "areaId", "type": "uint256"},
            {"internalType": "int256", "name": "x", "type": "int256"},
            {"internalType": "int256", "name": "y", "type": "int256"},
            {"internalType": "int256", "name": "z", "type": "int256"},
            {"internalType": "string", "name": "inventoryJson", "type": "string"},
            {"internalType": "string", "name": "reputationJson", "type": "string"},
            {"internalType": "string", "name": "achievementsJson", "type": "string"},
            {"internalType": "string", "name": "arenaStatsJson", "type": "string"},
            {"internalType": "string", "name": "glyphsJson", "type": "string"},
            {"internalType": "string", "name": "homebindJson", "type": "string"},
            {"internalType": "string", "name": "questStatusesJson", "type": "string"},
            {"internalType": "string", "name": "skillsJson", "type": "string"},
            {"internalType": "string", "name": "spellsJson", "type": "string"}
        ],
        "name": "updateCharacter",
        "outputs": [],
        "stateMutability": "nonpayable",
        "type": "function"
    },
    {
        "inputs": [{"internalType": "uint256", "name": "tokenId", "type": "uint256"}],
        "name": "getCharacterData",
        "outputs": [{"components": [
            {"internalType": "string", "name": "name", "type": "string"},
            {"internalType": "uint256", "name": "level", "type": "uint256"},
            {"internalType": "uint256", "name": "class", "type": "uint256"},
            {"internalType": "uint256", "name": "race", "type": "uint256"},
            {"internalType": "uint256", "name": "mapId", "type": "uint256"},
            {"internalType": "uint256", "name": "zoneId", "type": "uint256"},
            {"internalType": "uint256", "name": "areaId", "type": "uint256"},
            {"internalType": "int256", "name": "x", "type": "int256"},
            {"internalType": "int256", "name": "y", "type": "int256"},
            {"internalType": "int256", "name": "z", "type": "int256"},
            {"internalType": "string", "name": "inventoryJson", "type": "string"},
            {"internalType": "string", "name": "reputationJson", "type": "string"},
            {"internalType": "string", "name": "achievementsJson", "type": "string"},
            {"internalType": "string", "name": "arenaStatsJson", "type": "string"},
            {"internalType": "string", "name": "glyphsJson", "type": "string"},
            {"internalType": "string", "name": "homebindJson", "type": "string"},
            {"internalType": "string", "name": "questStatusesJson", "type": "string"},
            {"internalType": "string", "name": "skillsJson", "type": "string"},
            {"internalType": "string", "name": "spellsJson", "type": "string"}
        ], "internalType": "struct WoWCharacterNFT.CharacterData", "name": "", "type": "tuple"}],
        "stateMutability": "view",
        "type": "function"
    },
    {
        "inputs": [{"internalType": "address", "name": "playerAddress", "type": "address"}],
        "name": "getPlayerTokenId",
        "outputs": [{"internalType": "uint256", "name": "", "type": "uint256"}],
        "stateMutability": "view",
        "type": "function"
    }
]

contract = w3.eth.contract(address=contract_address, abi=wowCharacterNFT_abi)

account = w3.eth.account.from_key("YOUR PRIVATEKEY")

try:
    tx = contract.functions.mintCharacter(
        "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266",
        "Testasdasdsa",
        101,
        8,
        1,
        0,
        10,
        242,
        -10421,
        -972,
        45
    ).build_transaction({
        'from': account.address,
        'nonce': w3.eth.get_transaction_count(account.address),
        'gas': 1000000,
        'gasPrice': w3.eth.gas_price
    })

    signed_tx = account.sign_transaction(tx)
    tx_hash = w3.eth.send_raw_transaction(signed_tx.raw_transaction)
    receipt = w3.eth.wait_for_transaction_receipt(tx_hash)
    print(f"Transaction successful: {receipt['transactionHash'].hex()}")
except Exception as e:
    print(f"Error: {str(e)}")