from web3 import Web3

# Connect to the local Ethereum node
w3 = Web3(Web3.HTTPProvider('http://localhost:8545'))

# Set up the account
private_key = 'YOUR PRIVATEKEY'
account = w3.eth.account.from_key(private_key)

# Contract details
contract_address = '0x5FbDB2315678afecb367f032d93F642f64180aa3'
abi = [
    {
        "inputs": [],
        "name": "name",
        "outputs": [{"internalType": "string", "name": "", "type": "string"}],
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
        "inputs": [{"internalType": "address", "name": "account", "type": "address"}],
        "name": "balanceOf",
        "outputs": [{"internalType": "uint256", "name": "", "type": "uint256"}],
        "stateMutability": "view",
        "type": "function"
    }
]

contract = w3.eth.contract(address=contract_address, abi=abi)

def test_name():
    try:
        name = contract.functions.name().call()
        print('Token name:', name)
    except Exception as e:
        print('Error getting name:', str(e))

def test_get_owner():
    try:
        owner = contract.functions.getOwner().call()
        print('Contract owner:', owner)
    except Exception as e:
        print('Error getting owner:', str(e))

def test_mint():
    try:
        nonce = w3.eth.get_transaction_count(account.address)
        tx = contract.functions.mint(
            '0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266',
            w3.to_wei(1000, 'ether'),
            1  # mapId
        ).build_transaction({
            'from': account.address,
            'gas': 300000,
            'gasPrice': w3.eth.gas_price,
            'nonce': nonce,
        })
        signed_tx = account.sign_transaction(tx)
        tx_hash = w3.eth.send_raw_transaction(signed_tx.raw_transaction)
        tx_receipt = w3.eth.wait_for_transaction_receipt(tx_hash)
        print('Mint successful:', tx_receipt['transactionHash'].hex())
    except Exception as e:
        print('Mint failed:', str(e))

def test_burn():
    try:
        nonce = w3.eth.get_transaction_count(account.address)
        tx = contract.functions.burn(
            '0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266',
            w3.to_wei(5, 'ether'),
            1  # mapId
        ).build_transaction({
            'from': account.address,
            'gas': 300000,
            'gasPrice': w3.eth.gas_price,
            'nonce': nonce,
        })
        signed_tx = account.sign_transaction(tx)
        tx_hash = w3.eth.send_raw_transaction(signed_tx.raw_transaction)
        tx_receipt = w3.eth.wait_for_transaction_receipt(tx_hash)
        print('Burn successful:', tx_receipt['transactionHash'].hex())
    except Exception as e:
        print('Burn failed:', str(e))

def test_purchase_map():
    try:
        nonce = w3.eth.get_transaction_count(account.address)
        tx = contract.functions.purchaseMap(1).build_transaction({
            'from': account.address,
            'gas': 300000,
            'gasPrice': w3.eth.gas_price,
            'nonce': nonce,
        })
        signed_tx = account.sign_transaction(tx)
        tx_hash = w3.eth.send_raw_transaction(signed_tx.raw_transaction)
        tx_receipt = w3.eth.wait_for_transaction_receipt(tx_hash)
        print('Map purchase successful:', tx_receipt['transactionHash'].hex())
    except Exception as e:
        print('Map purchase failed:', str(e))

def test_get_map_owner():
    try:
        for map_id in [0, 1]:
            try:
                map_owner = contract.functions.getMapOwner(map_id).call()
                print(f'Map {map_id} owner:', map_owner)
            except Exception as e:
                print(f'Error getting owner for map {map_id}:', str(e))
    except Exception as e:
        print('Error in test_get_map_owner:', str(e))

def test_tax_system():
    try:
        # First, purchase a map
        test_purchase_map()
        
        # Get initial balances
        map_owner = contract.functions.getMapOwner(1).call()
        initial_owner_balance = contract.functions.balanceOf(map_owner).call()
        initial_player_balance = contract.functions.balanceOf('0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266').call()
        
        # Mint tokens (which should trigger tax payment)
        test_mint()
        
        # Get final balances
        final_owner_balance = contract.functions.balanceOf(map_owner).call()
        final_player_balance = contract.functions.balanceOf('0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266').call()
        
        # Calculate and print the differences
        owner_difference = final_owner_balance - initial_owner_balance
        player_difference = final_player_balance - initial_player_balance
        
        print(f"Map owner received {w3.from_wei(owner_difference, 'ether')} tokens as tax")
        print(f"Player received {w3.from_wei(player_difference, 'ether')} tokens after tax")
        
    except Exception as e:
        print('Error testing tax system:', str(e))

def test_map_purchased():
    try:
        for map_id in [0, 1]:
            try:
                owner = contract.functions.getMapOwner(map_id).call()
                if owner == '0x0000000000000000000000000000000000000000':
                    print(f'Map {map_id} has not been purchased yet')
                else:
                    print(f'Map {map_id} has been purchased by {owner}')
            except Exception as e:
                print(f'Error checking purchase status for map {map_id}:', str(e))
    except Exception as e:
        print('Error in test_map_purchased:', str(e))

if __name__ == '__main__':
    test_name()
    test_get_owner()
    test_map_purchased()  # Add this line
    test_purchase_map()
    test_get_map_owner()
    test_mint()
    test_burn()
    test_tax_system()
