# WoW Web3 Example

## Project Intentions

This project is a proof of concept designed to explore the extent to which game logic can be integrated with blockchain technology. The primary goal is to demonstrate how NFTs and tokens can be utilized within the World of Warcraft (WoW) environment in ways that go beyond mere monetization. By leveraging Web3, we aim to enhance the functionality of guilds, introduce new game mechanics, and create innovative interactions within the game.

## Key Points
1. Proof of Concept: This project serves as a proof of concept to see how much game logic can be routed through a blockchain. It is not intended to be a perfect or final solution. This is only an educational project.
2. Server-Side Transactions: Currently, the server is responsible for sending transactions to the blockchain, not the client (wallet). This approach is prone to exploitation, but it is necessary because the WoW client cannot be modified to sign and send transactions. Even if it were possible, it would be vulnerable to user exploits.
3. Middleware Server: The middleware server handles blockchain transactions, acting as an intermediary between the game client and the blockchain. This approach provides a balance between security and functionality.
4. DAO Governance: To limit which servers can write to the contract, a DAO and proposal process can be implemented. This would allow the community to vote on new servers and ensure that only trusted servers can interact with the blockchain.
5. Server Verification: Additional proofs can be added to verify that the server is running the default version of AzerothCore, enhancing security and trust.

## Use Cases
1. Guilds as DAOs: Web3 can enable guilds to function as decentralized autonomous organizations (DAOs), enhancing their governance and decision-making processes. Examples include staking tokens, distributing rewards, and managing guild assets.
2. Bounties: Real tokens can be used to place bounties both in-game and outside of the game. This creates new opportunities for players to earn rewards and engage in various activities.
3. Map Ownership: Introducing mechanics like owning maps for a limited time can provide additional income and taxes for players. This adds a new layer of strategy and competition to the game.
4. Character NFTs: Character NFTs can be used to save player progress and make it transferable between servers. This allows players to retain their achievements and items when switching servers. Additionally, character NFTs can be used to represent characters in other games (e.g., 2D WoW, Snake).
5. Auction House Derivatives: Adding options (calls, puts) to the auction house can enable gambling and investing on a new level. Players can trade derivatives of in-game items, creating a dynamic and complex market.

## Educational Purpose

This project is intended for educational purposes only. It aims to showcase the potential of integrating Web3 with WoW servers and to spark discussions on how this technology can be further enhanced and utilized. We welcome feedback and suggestions on how to improve this concept and make it more secure and practical.

Is this useful, or how could it be enhanced? This project is a starting point for exploring the possibilities of Web3 in gaming, and we are eager to hear your thoughts and ideas.

## Architecture
Sure, let's update the architecture description to reflect that the middleware server communicates with the WoW emulator (server) and not the client. The WoW server is the sole communicator with the player and the middleware, which connects to the blockchain.

### Architecture Diagram Description

1. **Player (WoW Game Client)**
   - Interacts with the WoW Server.
   - Cannot directly interact with the middleware or blockchain.

2. **WoW Server (AzerothCore with Eluna)**
   - Handles player interactions and game logic.
   - Communicates with the Middleware Server via HTTP requests.

3. **Middleware Server (Flask Server)**
   - Handles HTTP requests from the WoW Server.
   - Interacts with the Blockchain via Web3.py.
   - Contains business logic for minting, burning tokens, and handling character NFTs.
   - Verifies server integrity and handles DAO proposals.

4. **Blockchain (Ethereum Network)**
   - Smart contracts deployed on the Ethereum network.
   - Handles token transactions, character NFTs, and DAO governance.
   - Interacts with the Middleware Server via Web3.js/Web3.py.

5. **Database (MySQL)**
   - Stores game-related data.
   - Interacts with the Middleware Server for data persistence.

### Components and Interactions

1. **Player (WoW Game Client)**
   - Interacts with the WoW Server for various actions (e.g., gameplay, transactions).

2. **WoW Server (AzerothCore with Eluna)**
   - Receives player interactions and processes game logic.
   - Sends HTTP requests to the Middleware Server for blockchain-related actions.

3. **Middleware Server (Flask Server)**
   - Receives HTTP requests from the WoW Server.
   - Processes requests and interacts with the Blockchain via Web3.py.
   - Queries and updates the MySQL Database as needed.
   - Sends responses back to the WoW Server.

4. **Blockchain (Ethereum Network)**
   - Executes smart contract functions (e.g., minting, burning tokens, managing character NFTs).
   - Stores data on the blockchain (e.g., token balances, character NFT ownership).

5. **Database (MySQL)**
   - Stores game-related data (e.g., player information, game state).
   - Provides data to the Middleware Server upon request.

### Visual Representation

You can visualize the architecture as follows:

```
+-------------------+          +-------------------+          +-------------------+
|                   |          |                   |          |                   |
|  WoW Game Client  | <------> |     WoW Server    | <------> | Middleware Server |
|                   |          | (AzerothCore)     |          |   (Flask Server)  |
|                   |          |                   |          |                   |
+-------------------+          +-------------------+          +-------------------+
        ^                             ^                             ^
        |                             |                             |
        |                             |                             |
        v                             v                             v
+-------------------+          +-------------------+          +-------------------+
|                   |          |                   |          |                   |
|      Player       |          |       MySQL       |          |    Blockchain     |
|                   |          |     Database      |          | (Ethereum Network)|
|                   |          |                   |          |                   |
+-------------------+          +-------------------+          +-------------------+
```


This architecture ensures that the game logic is integrated with blockchain technology while maintaining a secure and functional system.

## Prerequisites
- AzerothCore with Eluna: Ensure that AzerothCore with Eluna is installed.
- Lua Scripts: Move the Lua scripts to the binary folder of your AzerothCore installation.
- MySQL Database: Ensure that the MySQL database is set up and running.
- Run all the sql scripts in `lua_scripts/sql` in your database.

## Setup

### Python Environment

1. Install Python: Ensure Python is installed on your system.
2. Create a Virtual Environment:
```bash
python3 -m venv venv
```
3. Activate the Virtual Environment:
```bash
source venv/bin/activate
``` 
4. Install Requirements:
```bash
pip install -r requirements.txt
```

### Running the Flask Server
1. Start the Flask Server:
```bash
python3 app.py
```

## Solidity Environment
1. Install Forge and Anvil
```bash
curl -L https://foundry.paradigm.xyz | bash
foundryup
```

2. Start Anvil
```bash
anvil -b 5
```

3. Deploy Contracts

First export the private key of the account you want to deploy the contracts from. For this you can choose one of the displayed private keys in the Anvil terminal. 

```bash
export PRIVATE_KEY=0x...
```


Then deploy the contracts with the following commands:

```bash 
forge script script/bountie.s.sol:DeployBountyNFTScript --rpc-url http://localhost:8545 --broadcast --via-ir
forge script script/character.s.sol:DeployWowCharacterScript --rpc-url http://localhost:8545 --broadcast --via-ir
forge script script/DeployGuildDAO.s.sol:DeployGuildDAOScript --rpc-url http://localhost:8545 --broadcast --via-ir
``` 

This should result in an output similar to this:

```bash
  WowToken deployed at: 0x5FbDB2315678afecb367f032d93F642f64180aa3
  BountyNFT deployed at: 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512
  character Contract Address: 0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0
  GuildDAO deployed at: 0xDc64a140Aa3E981100a9becA4E685f962f0cF6C9
```

## Web Interface
1. Open the Web Interface: Open your browser and navigate to `http://localhost:3000` 
2. If you have metamask installed, you can connect to the local network by selecting `Localhost 8545` from the networks dropdown.

## Examples

Minting and Burning is always associated with a Map (zoneID). The Map ID is a number that represents a zone in the game. For example, the map ID for Elwynn Forest is 1. 

This association is important, because if the character is in a specific zone, there could be a map tax to a specific owner (guild, character) ...


### Minting Tokens

```bash
curl -X POST http://localhost:3000/mint \
-H "Content-Type: application/json" \
-d '{
    "to": "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266",
    "amount": "429496",
    "mapId": "1"
}'
```

### Burning Tokens
```bash
curl -X POST http://localhost:3000/burn \
-H "Content-Type: application/json" \
-d '{
    "from": "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266",
    "amount": "9900000000000000000000",
    "mapId": "1"
}'
```

### Getting Player TokenID
```bash
curl -s 'http://localhost:3000/get_player_token_id?playerAddress=0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266'
```

### Getting Character NFT
```bash
curl -s 'http://localhost:3000/get_character?tokenId=1'
```

### Bounties and DAOs

#### Approve DAO Contract to spend tokens
```bash
cast send 0x5FbDB2315678afecb367f032d93F642f64180aa3 "approve(address,uint256)" $DAO_ADDRESS 100000 \
  --from 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 \
  --rpc-url http://localhost:8545 \
  --private-key $PRIVATE_KEY
```

#### Stake Tokens
```bash
cast send $DAO_ADDRESS "stake(uint256)" 100000 \
  --from 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 \
  --rpc-url http://localhost:8545 \
  --private-key $PRIVATE_KEY
```

#### Check Voting Power
```bash
cast call $DAO_ADDRESS "getVotes(address)(uint256)" 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 \
  --rpc-url http://localhost:8545
```

#### Propose

```bash
cast send $DAO_ADDRESS "propose(address[],uint256[],bytes[],string)" \
  "[0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266]" "[0]" "[0x]" "My proposal description" \
  --rpc-url http://localhost:8545 \
  --private-key $PRIVATE_KEY \
  --gas-limit 1000000
```
```bash
cast logs $DAO_ADDRESS --rpc-url http://localhost:8545

cast call $DAO_ADDRESS "getVotes(address)(uint256)" "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266" --rpc-url http://localhost:8545

#approve dao contract to spend tokens
cast send 0x5FbDB2315678afecb367f032d93F642f64180aa3 "approve(address,uint256)" $DAO_ADDRESS 100000 \
  --from 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 \
  --rpc-url http://localhost:8545 \
  --private-key $PRIVATE_KEY

#check balance

cast call 0x5FbDB2315678afecb367f032d93F642f64180aa3 "balanceOf(address)(uint256)" 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 \
  --rpc-url http://localhost:8545

#stake

cast send $DAO_ADDRESS "stake(uint256)" 100000 \
  --from 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 \
  --rpc-url http://localhost:8545 \
  --private-key $PRIVATE_KEY

#check voting power
cast call $DAO_ADDRESS "getVotes(address)(uint256)" 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 \
  --rpc-url http://localhost:8545


cast call $DAO_ADDRESS "name()(string)" --rpc-url http://localhost:8545

cast call $DAO_ADDRESS "getVotes(address)(uint256)" 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 --rpc-url http://localhost:8545

cast call $DAO_ADDRESS "proposalThreshold()(uint256)" --rpc-url http://localhost:8545

cast call $DAO_ADDRESS "quorumVotes()(uint256)" --rpc-url http://localhost:8545

CURRENT_BLOCK=$(cast block-number --rpc-url http://localhost:8545)

cast call $TOKEN_ADDRESS "delegates(address)(address)" 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 --rpc-url http://localhost:8545
cast send $TOKEN_ADDRESS "delegate(address)" 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 --from 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 --rpc-url http://localhost:8545 --private-key $PRIVATE_KEY
cast call $TOKEN_ADDRESS "getVotes(address)(uint256)" 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 --rpc-url http://localhost:8545
cast call $TOKEN_ADDRESS "getVotes(address)(uint256)" 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 --rpc-url http://localhost:8545
cast call $TOKEN_ADDRESS "delegates(address)(address)" 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 --rpc-url http://localhost:8545

curl -X POST --data '{"jsonrpc":"2.0","method":"eth_getLogs","params":[{"address":"'$DAO_ADDRESS'","fromBlock":"0x0","toBlock":"latest"}],"id":1}' -H "Content-Type: application/json" http://localhost:8545

cast keccak "ProposalCreated(uint256,address,address[],uint256[],string[],bytes[],uint256,uint256,string)"
```
## Additional commands

### Start MYSQL
```bash
brew services start mysql
```
