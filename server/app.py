import os
from flask import Flask, jsonify, request, render_template
from web3 import Web3
import json
import logging
import web3
from web3.datastructures import AttributeDict
from flask_cors import CORS
from web3.exceptions import ContractLogicError, TransactionNotFound
import time

# Get the directory of the current file (app.py)
current_dir = os.path.dirname(os.path.abspath(__file__))

# Create the Flask app with the correct template folder
app = Flask(__name__, template_folder=os.path.join(current_dir, 'templates'))
CORS(app)

port = 3000

w3 = Web3(Web3.HTTPProvider("http://localhost:8545"))
# FILL IN YOUR PRIVATE KEY
private_key = "FILL IN YOUR KEY"
account = w3.eth.account.from_key(private_key)

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
        "inputs": [
            {"internalType": "address", "name": "spender", "type": "address"},
            {"internalType": "uint256", "name": "amount", "type": "uint256"}
        ],
        "name": "approve",
        "outputs": [{"internalType": "bool", "name": "", "type": "bool"}],
        "stateMutability": "nonpayable",
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
            {
                "internalType": "uint256",
                "name": "tokenId",
                "type": "uint256"
            },
            {
                "components": [
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
                "internalType": "struct WoWCharacterNFT.CharacterUpdateData",
                "name": "updateData",
                "type": "tuple"
            }
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

# Contract address (replace with your actual deployed contract address)
contract_address_character = "0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0"
contract_address = "0x5FbDB2315678afecb367f032d93F642f64180aa3"
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def serialize_web3_object(obj):
    if isinstance(obj, AttributeDict):
        return {k: serialize_web3_object(v) for k, v in obj.items()}
    if isinstance(obj, (bytes, bytearray)):
        return obj.hex()
    if isinstance(obj, list):
        return [serialize_web3_object(item) for item in obj]
    return obj

# Load the area names from the JSON file
json_path = os.path.join(current_dir, 'areatable_dbc_202410171241.json')

with open(json_path, 'r') as f:
    area_data = json.load(f)

# Extract the area information from the loaded JSON
area_info = area_data["SELECT ID, AreaName_Lang_enUS, ParentAreaID \nFROM areatable_dbc"]

# Load the ABI and bytecode from the files generated by Foundry
with open('../solidity/out/dao.sol/GuildDAO.json', 'r') as f:
    contract_json = json.load(f)
    GUILD_DAO_ABI = contract_json['abi']

# Extract and format the DAO bytecode
if 'bytecode' in contract_json and 'object' in contract_json['bytecode']:
    GUILD_DAO_BYTECODE = contract_json['bytecode']['object']
    # Ensure the bytecode starts with '0x'
    if not GUILD_DAO_BYTECODE.startswith('0x'):
        GUILD_DAO_BYTECODE = '0x' + GUILD_DAO_BYTECODE
else:
    raise ValueError("DAO bytecode not found in the expected format")

# Load BountyNFT contract data
with open('../solidity/out/bountie.sol/BountyNFT.json', 'r') as f:
    bounty_contract_json = json.load(f)
    bounty_nft_abi = bounty_contract_json['abi']

# Extract and format the BountyNFT bytecode 
if 'bytecode' in bounty_contract_json and 'object' in bounty_contract_json['bytecode']:
    BOUNTY_NFT_BYTECODE = bounty_contract_json['bytecode']['object']
    if not BOUNTY_NFT_BYTECODE.startswith('0x'):
        BOUNTY_NFT_BYTECODE = '0x' + BOUNTY_NFT_BYTECODE
else:
    raise ValueError("BountyNFT bytecode not found in the expected format")

# Print the first few characters of both bytecodes to verify
print(f"DAO Bytecode prefix: {GUILD_DAO_BYTECODE[:20]}")
print(f"BountyNFT Bytecode prefix: {BOUNTY_NFT_BYTECODE[:20]}")

bounty_nft_address = "0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512" # Add the deployed BountyNFT contract address

@app.route('/')
def index():
    return render_template('index.html')

@app.route('/api/map_owners')
def get_map_owners():
    contract = w3.eth.contract(address=contract_address, abi=wowToken_abi)
    map_owners = {}
    for i in range(250):  # Adjust the range as needed
        owner = contract.functions.getMapOwner(i).call()
        if owner != '0x0000000000000000000000000000000000000000':
            map_owners[i] = owner
    return jsonify(map_owners)

@app.route('/api/area_names')
def get_area_names():
    area_names = {}
    for area in area_info:
        area_names[area['ID']] = {
            'name': area['AreaName_Lang_enUS'],
            'parentId': area['ParentAreaID']
        }
    return jsonify(area_names)

@app.route('/mint', methods=['POST'])
def mint_tokens():
    try:
        data = request.get_json(force=True)
        
        # Handle the case where the entire JSON is a string
        if isinstance(data, str):
            try:
                data = json.loads(data)
            except json.JSONDecodeError:
                return jsonify({'success': False, 'error': 'Invalid JSON string'}), 400
        
        to_address = data['to']
        amount = int(data['amount'])
        map_id = int(data['mapId'])

        contract = w3.eth.contract(address=contract_address, abi=wowToken_abi)

        transaction = contract.functions.mint(to_address, amount, map_id).build_transaction({
            'from': account.address,
            'nonce': w3.eth.get_transaction_count(account.address),
            'gas': 300000,
            'gasPrice': w3.eth.gas_price
        })

        signed_txn = w3.eth.account.sign_transaction(transaction, private_key)
        tx_hash = w3.eth.send_raw_transaction(signed_txn.raw_transaction)
        tx_receipt = w3.eth.wait_for_transaction_receipt(tx_hash)

        if tx_receipt['status'] == 1:
            return jsonify({'success': True, 'transaction_hash': tx_hash.hex()}), 200
        else:
            return jsonify({'success': False, 'error': 'Transaction failed'}), 400

    except json.JSONDecodeError as e:
        return jsonify({'success': False, 'error': f'Invalid JSON: {str(e)}'}), 400
    except KeyError as e:
        return jsonify({'success': False, 'error': f'Missing required field: {str(e)}'}), 400
    except ValueError as e:
        return jsonify({'success': False, 'error': f'Invalid value: {str(e)}'}), 400
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500

@app.route('/burn', methods=['POST'])
def burn_tokens():
    try:
        data = request.get_json()
        from_address = data['from']
        amount = int(data['amount'])
        map_id = int(data['mapId'])

        logger.info(f"Attempting to burn {amount} tokens from {from_address} for map {map_id}")

        contract = w3.eth.contract(address=contract_address, abi=wowToken_abi)

        # Check balance
        balance = contract.functions.balanceOf(from_address).call()
        logger.info(f"Current balance of {from_address}: {balance}")
        if balance < amount:
            return jsonify({'success': False, 'error': f'Insufficient balance. Address has {balance} tokens, trying to burn {amount}'}), 400

        # Estimate gas for the transaction
        try:
            gas_estimate = contract.functions.burn(from_address, amount, map_id).estimate_gas({'from': account.address})
            logger.info(f"Estimated gas: {gas_estimate}")
        except Exception as e:
            logger.error(f"Gas estimation failed: {str(e)}")
            return jsonify({'success': False, 'error': f'Gas estimation failed: {str(e)}'}), 400

        transaction = contract.functions.burn(from_address, amount, map_id).build_transaction({
            'from': account.address,
            'nonce': w3.eth.get_transaction_count(account.address),
            'gas': gas_estimate,
            'gasPrice': w3.eth.gas_price
        })

        signed_txn = w3.eth.account.sign_transaction(transaction, private_key)
        tx_hash = w3.eth.send_raw_transaction(signed_txn.raw_transaction)
        
        logger.info(f"Transaction sent: {tx_hash.hex()}")
        
        tx_receipt = w3.eth.wait_for_transaction_receipt(tx_hash)

        if tx_receipt['status'] == 1:
            logger.info(f"Burn successful: {tx_hash.hex()}")
            return jsonify({'success': True, 'transaction_hash': tx_hash.hex()}), 200
        else:
            logger.error(f"Transaction failed: {serialize_web3_object(tx_receipt)}")
            return jsonify({'success': False, 'error': 'Transaction failed', 'receipt': serialize_web3_object(tx_receipt)}), 400

    except Exception as e:
        logger.error(f"Error in burn_tokens: {str(e)}", exc_info=True)
        return jsonify({'success': False, 'error': str(e)}), 500

@app.route('/purchase_map', methods=['POST'])
def purchase_map():
    try:
        data = request.get_json()
        map_id = int(data['mapId'])
        buyer_address = data['buyer']

        contract = w3.eth.contract(address=contract_address, abi=wowToken_abi)

        transaction = contract.functions.purchaseMap(map_id).build_transaction({
            'from': buyer_address,
            'nonce': w3.eth.get_transaction_count(buyer_address),
            'gas': 300000,
            'gasPrice': w3.eth.gas_price
        })

        signed_txn = w3.eth.account.sign_transaction(transaction, private_key)
        tx_hash = w3.eth.send_raw_transaction(signed_txn.raw_transaction)
        tx_receipt = w3.eth.wait_for_transaction_receipt(tx_hash)

        if tx_receipt['status'] == 1:
            return jsonify({'success': True, 'transaction_hash': tx_hash.hex()}), 200
        else:
            return jsonify({'success': False, 'error': 'Transaction failed'}), 400

    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500

@app.route('/get_map_owner', methods=['GET'])
def get_map_owner():
    try:
        map_id = int(request.args.get('mapId'))

        contract = w3.eth.contract(address=contract_address, abi=wowToken_abi)
        owner = contract.functions.getMapOwner(map_id).call()

        return jsonify({'success': True, 'owner': owner}), 200

    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500

@app.route('/balance', methods=['GET'])
def get_balance():
    try:
        address = request.args.get('address')
        if not address:
            return jsonify({'success': False, 'error': 'Address parameter is required'}), 400

        contract = w3.eth.contract(address=contract_address, abi=wowToken_abi)
        balance = contract.functions.balanceOf(address).call()

        return jsonify({'success': True, 'address': address, 'balance': str(balance)}), 200

    except Exception as e:
        logger.error(f"Error in get_balance: {str(e)}")
        return jsonify({'success': False, 'error': str(e)}), 500

@app.route('/mint_character', methods=['POST'])
def mint_character():
    try:
        data = request.get_json()
        player_address = data['playerAddress']
        name = data['name']
        level = int(data['level'])
        class_ = int(data['class'])
        race = int(data['race'])
        map_id = int(data['mapId'])
        zone_id = int(data['zoneId'])
        area_id = int(data['areaId'])
        x = int(data['x'])
        y = int(data['y'])
        z = int(data['z'])

        contract = w3.eth.contract(address=contract_address_character, abi=wowCharacterNFT_abi)

        # Check if the player already has a character NFT
        existing_token_id = contract.functions.getPlayerTokenId(player_address).call()
        if existing_token_id != 0:
            return jsonify({'success': False, 'error': 'Player already has a character NFT'}), 400

        # Log the transaction details
        logger.info(f"Minting character for {player_address}: {name}, Level {level}, Class {class_}, Race {race}")

        transaction = contract.functions.mintCharacter(
            player_address, name, level, class_, race, map_id, zone_id, area_id, x, y, z
        ).build_transaction({
            'from': account.address,
            'nonce': w3.eth.get_transaction_count(account.address),
            'gas': 500000000,
            'gasPrice': w3.eth.gas_price
        })

        signed_txn = w3.eth.account.sign_transaction(transaction, private_key)
        tx_hash = w3.eth.send_raw_transaction(signed_txn.raw_transaction)
        
        # Log the transaction hash
        logger.info(f"Transaction sent: {tx_hash.hex()}")

        tx_receipt = w3.eth.wait_for_transaction_receipt(tx_hash)

        if tx_receipt['status'] == 1:
            token_id = contract.functions.getPlayerTokenId(player_address).call()
            logger.info(f"Character minted successfully. Token ID: {token_id}")
            return jsonify({'success': True, 'token_id': token_id, 'transaction_hash': tx_hash.hex()}), 200
        else:
            logger.error(f"Transaction failed. Receipt: {tx_receipt}")
            return jsonify({'success': False, 'error': 'Transaction failed'}), 400

    except Exception as e:
        logger.error(f"Error in mint_character: {str(e)}")
        return jsonify({'success': False, 'error': str(e)}), 500

@app.route('/update_character', methods=['POST'])
def update_character():
    try:
        data = request.get_json()
        token_id = int(data['tokenId'])

        # Create the CharacterUpdateData struct
        update_data = (
            int(data['level']),
            int(data['mapId']),
            int(data['zoneId']),
            int(data['areaId']),
            int(data['x']),
            int(data['y']),
            int(data['z']),
            json.dumps(data['inventory']),
            json.dumps(data['reputation']),
            json.dumps(data['achievements']),
            json.dumps(data['arenaStats']),
            json.dumps(data['glyphs']),
            json.dumps(data['homebind']),
            json.dumps(data['questStatuses']),
            json.dumps(data['skills']),
            json.dumps(data['spells'])
        )

        logger.info(f"Updating character with token ID: {token_id}")
        logger.info(f"Update data: {update_data}")

        contract = w3.eth.contract(address=contract_address_character, abi=wowCharacterNFT_abi)

        # contract_owner = contract.functions.owner().call()
        # if contract_owner.lower() != account.address.lower():
        #     logger.error(f"Account {account.address} is not the contract owner. Owner is {contract_owner}")
        #     return jsonify({'success': False, 'error': 'Not authorized to update character'}), 403

        transaction = contract.functions.updateCharacter(token_id, update_data).build_transaction({
            'from': account.address,
            'nonce': w3.eth.get_transaction_count(account.address),
            'gas': 5000000,  # Increased gas limit to 5 million
            'gasPrice': w3.eth.gas_price
        })

        signed_txn = w3.eth.account.sign_transaction(transaction, private_key)
        tx_hash = w3.eth.send_raw_transaction(signed_txn.raw_transaction)
        logger.info(f"Transaction sent: {tx_hash.hex()}")

        tx_receipt = w3.eth.wait_for_transaction_receipt(tx_hash)
        logger.info(f"Transaction receipt: {tx_receipt}")

        if tx_receipt['status'] == 1:
            logger.info("Transaction successful")
            return jsonify({'success': True, 'transaction_hash': tx_hash.hex()}), 200
        else:
            logger.error(f"Transaction failed. Receipt: {tx_receipt}")
            return jsonify({'success': False, 'error': 'Transaction failed'}), 400

    except Exception as e:
        logger.error(f"Error in update_character: {str(e)}")
        return jsonify({'success': False, 'error': str(e)}), 500

@app.route('/get_character', methods=['GET'])
def get_character():
    try:
        token_id = int(request.args.get('tokenId'))

        contract = w3.eth.contract(address=contract_address_character, abi=wowCharacterNFT_abi)
        character_data = contract.functions.getCharacterData(token_id).call()

        return jsonify({
            'success': True,
            'character': {
                'name': character_data[0],
                'level': character_data[1],
                'class': character_data[2],
                'race': character_data[3],
                'mapId': character_data[4],
                'zoneId': character_data[5],
                'areaId': character_data[6],
                'x': character_data[7],
                'y': character_data[8],
                'z': character_data[9],
                'inventory': json.loads(character_data[10]),
                'reputation': json.loads(character_data[11]),
                'achievements': json.loads(character_data[12]),
                'arenaStats': json.loads(character_data[13]),
                'glyphs': json.loads(character_data[14]),
                'homebind': json.loads(character_data[15]),
                'questStatuses': json.loads(character_data[16]),
                'skills': json.loads(character_data[17]),
                'spells': json.loads(character_data[18])
            }
        }), 200

    except Exception as e:
        logger.error(f"Error in get_character: {str(e)}")
        return jsonify({'success': False, 'error': str(e)}), 500

@app.route('/get_player_token_id', methods=['GET'])
def get_player_token_id():
    try:
        player_address = request.args.get('playerAddress')
        if not player_address:
            return jsonify({'success': False, 'error': 'Player address is required'}), 400

        contract = w3.eth.contract(address=contract_address_character, abi=wowCharacterNFT_abi)
        try:
            token_id = contract.functions.getPlayerTokenId(player_address).call()
            return jsonify({'success': True, 'tokenId': token_id}), 200
        except Exception as e:
            if "execution reverted" in str(e):
                return jsonify({'success': True, 'tokenId': None}), 200
            else:
                raise e

    except Exception as e:
        logger.error(f"Error in get_player_token_id: {str(e)}")
        return jsonify({'success': False, 'error': str(e)}), 500

@app.route('/api/create_dao', methods=['POST'])
def create_dao():
    try:
        data = request.json
        logger.info(f"Received data: {data}")

        guild_name = data['guildName']
        leader_address = data['leaderWallet']
        token_address = Web3.to_checksum_address(data['tokenAddress'])
        voting_delay = int(data['votingDelay'])
        voting_period = int(data['votingPeriod'])
        proposal_threshold = int(data['proposalThreshold'])
        quorum_percentage = int(data['quorumPercentage'])

        logger.info(f"Processed input parameters: guild_name={guild_name}, leader_address={leader_address}, "
                    f"token_address={token_address}, voting_delay={voting_delay}, voting_period={voting_period}, "
                    f"proposal_threshold={proposal_threshold}, quorum_percentage={quorum_percentage}")

        # Deploy the contract
        contract = w3.eth.contract(abi=GUILD_DAO_ABI, bytecode=GUILD_DAO_BYTECODE)
        logger.info("Contract instance created")

        # Estimate gas
        gas_estimate = contract.constructor(
            guild_name,
            token_address,
            voting_delay,
            voting_period,
            proposal_threshold,
            quorum_percentage
        ).estimate_gas({'from': account.address})

        logger.info(f"Estimated gas: {gas_estimate}")

        # Prepare the transaction with increased gas limit
        transaction = contract.constructor(
            guild_name,
            token_address,
            voting_delay,
            voting_period,
            proposal_threshold,
            quorum_percentage
        ).build_transaction({
            'from': account.address,
            'gas': gas_estimate * 2,  # Double the estimated gas
            'gasPrice': w3.eth.gas_price,
            'nonce': w3.eth.get_transaction_count(account.address),
        })

        logger.info(f"Transaction prepared: {transaction}")

        # Sign and send the transaction
        signed_txn = w3.eth.account.sign_transaction(transaction, private_key)
        tx_hash = w3.eth.send_raw_transaction(signed_txn.raw_transaction)
        logger.info(f"Transaction sent. Hash: {tx_hash.hex()}")

        # Wait for the transaction to be mined
        tx_receipt = w3.eth.wait_for_transaction_receipt(tx_hash)
        logger.info(f"Transaction receipt: {tx_receipt}")

        contract_address = tx_receipt['contractAddress']
        logger.info(f"DAO contract deployed at: {contract_address}")

        # Get the contract ABI
        contract_abi = json.dumps(GUILD_DAO_ABI)

        return jsonify({
            'status': 'success',
            'message': 'DAO created successfully',
            'contractAddress': contract_address,
            'contractABI': contract_abi
        }), 200

    except Exception as e:
        logger.error(f"Error in create_dao: {str(e)}", exc_info=True)
        return jsonify({
            'status': 'error',
            'message': str(e)
        }), 500

@app.route('/create_bounty', methods=['POST'])
def create_bounty():
    try:
        data = request.get_json()
        creator = data['creator']
        target = data['target']
        amount = int(data['amount'])

        bounty_contract = w3.eth.contract(address=bounty_nft_address, abi=bounty_nft_abi)
        wow_token_contract = w3.eth.contract(address=contract_address, abi=wowToken_abi)

        # Get the latest nonce
        nonce = w3.eth.get_transaction_count(account.address, 'pending')

        # Get the current gas price and increase it by 10%
        gas_price = int(w3.eth.gas_price * 1.1)

        # Approve WowToken spending
        approve_tx = wow_token_contract.functions.approve(bounty_nft_address, amount).build_transaction({
            'from': account.address,
            'nonce': nonce,
            'gas': 100000,
            'gasPrice': gas_price
        })
        signed_approve_tx = w3.eth.account.sign_transaction(approve_tx, private_key)
        approve_tx_hash = w3.eth.send_raw_transaction(signed_approve_tx.raw_transaction)

        # Wait for the approval transaction to be mined
        while True:
            try:
                approve_receipt = w3.eth.get_transaction_receipt(approve_tx_hash)
                if approve_receipt is not None:
                    break
            except TransactionNotFound:
                time.sleep(1)

        # Increment nonce for the next transaction
        nonce += 1

        # Create bounty
        transaction = bounty_contract.functions.createBounty(w3.to_checksum_address(target), amount).build_transaction({
            'from': account.address,
            'nonce': nonce,
            'gas': 300000,
            'gasPrice': gas_price
        })

        signed_txn = w3.eth.account.sign_transaction(transaction, private_key)
        tx_hash = w3.eth.send_raw_transaction(signed_txn.raw_transaction)

        # Wait for the transaction to be mined
        tx_receipt = w3.eth.wait_for_transaction_receipt(tx_hash)

        if tx_receipt['status'] == 1:
            return jsonify({'success': True, 'transaction_hash': tx_hash.hex()}), 200
        else:
            return jsonify({'success': False, 'error': 'Transaction failed'}), 400

    except ContractLogicError as e:
        return jsonify({'success': False, 'error': str(e)}), 400
    except Exception as e:
        app.logger.error(f"Error in create_bounty: {str(e)}", exc_info=True)
        return jsonify({'success': False, 'error': str(e)}), 500

@app.route('/claim_bounty', methods=['POST'])
def claim_bounty():
    try:
        data = request.get_json()
        killer = data['killer']
        killed = data['killed']

        contract = w3.eth.contract(address=bounty_nft_address, abi=bounty_nft_abi)

        # Find the bounty for the killed player
        bounty_id = None
        max_token_id = 1000  # Set a reasonable upper limit
        for token_id in range(1, max_token_id + 1):
            try:
                bounty = contract.functions.getBounty(token_id).call()
                if bounty[1].lower() == killed.lower() and not bounty[3]:  # Check if target matches and bounty is not claimed
                    bounty_id = token_id
                    break
            except Exception as e:
                # If we get an error, assume we've reached the end of the bounties
                break

        if bounty_id is None:
            return jsonify({'success': False, 'error': 'No active bounty found for the killed player'}), 400

        # Check contract state before submitting transaction
        bounty = contract.functions.getBounty(bounty_id).call()
        if bounty[3]:  # Check if bounty is already claimed
            return jsonify({'success': False, 'error': 'Bounty already claimed'}), 400

        # Claim the bounty
        transaction = contract.functions.claimBounty(bounty_id, killer).build_transaction({
            'from': account.address,
            'nonce': w3.eth.get_transaction_count(account.address),
            'gas': 300000,
            'gasPrice': w3.eth.gas_price
        })

        signed_txn = w3.eth.account.sign_transaction(transaction, private_key)
        tx_hash = w3.eth.send_raw_transaction(signed_txn.raw_transaction)
        
        try:
            tx_receipt = w3.eth.wait_for_transaction_receipt(tx_hash, timeout=120)  # Wait up to 2 minutes
            if tx_receipt['status'] == 1:
                # Get the updated bounty information
                updated_bounty = contract.functions.getBounty(bounty_id).call()
                return jsonify({
                    'success': True, 
                    'transaction_hash': tx_hash.hex(), 
                    'amount': updated_bounty[2],
                    'new_owner': killer
                }), 200
            else:   
                return jsonify({
                    'success': False, 
                    'error': 'Transaction failed', 
                    'tx_receipt': json.loads(web3.toJSON(tx_receipt))
                }), 400
        except Exception as e:
            return jsonify({
                'success': False, 
                'error': f'Transaction failed: {str(e)}', 
                'tx_hash': tx_hash.hex()
            }), 400

    except ContractLogicError as e:
        return jsonify({'success': False, 'error': f'Contract logic error: {str(e)}'}), 400
    except Exception as e:
        app.logger.error(f"Error in claim_bounty: {str(e)}", exc_info=True)
        return jsonify({'success': False, 'error': str(e)}), 500

@app.route('/list_bounties', methods=['GET'])
def list_bounties():
    try:
        contract = w3.eth.contract(address=bounty_nft_address, abi=bounty_nft_abi)
        total_supply = contract.functions.totalSupply().call()

        bounties = []
        for i in range(1, total_supply + 1):
            bounty = contract.functions.getBounty(i).call()
            if not bounty[3]:  # If not claimed
                bounties.append({
                    'id': i,
                    'creator': bounty[0],
                    'target': bounty[1],
                    'amount': bounty[2]
                })

        return jsonify({'success': True, 'bounties': bounties}), 200

    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500

@app.route('/fetch_bounties', methods=['GET'])
def fetch_bounties():
    app.logger.info("Fetch bounties endpoint called")
    try:
        contract = w3.eth.contract(address=bounty_nft_address, abi=bounty_nft_abi)
        
        bounties = []
        token_id = 1
        max_iterations = 12  # Set a reasonable upper limit

        while token_id <= max_iterations:
            try:
                bounty = contract.functions.getBounty(token_id).call()
                bounties.append({
                    'tokenId': token_id,
                    'creator': bounty[0],
                    'target': bounty[1],
                    'amount': bounty[2],
                    'claimed': bounty[3]
                })
                token_id += 1
            except ContractLogicError as e:
                # This error is likely due to trying to access a non-existent bounty
                app.logger.info(f"Reached end of bounties at token_id {token_id}")
                break
            except Exception as e:
                app.logger.error(f"Error fetching bounty {token_id}: {str(e)}")
                # Continue to the next token_id instead of breaking
                token_id += 1

        if token_id > max_iterations:
            app.logger.warning(f"Reached maximum iterations ({max_iterations}) when fetching bounties")

        app.logger.info(f"Fetched {len(bounties)} bounties")
        return jsonify({'success': True, 'bounties': bounties}), 200

    except Exception as e:
        app.logger.error(f"Error in fetch_bounties: {str(e)}", exc_info=True)
        return jsonify({'success': False, 'error': str(e)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=port, debug=True)
