-include .env

.PHONY: all test clean build \
	deploy deploy-sepolia deploy-mainnet \
	fund fund-sepolia fund-mainnet \
	withdraw withdraw-sepolia withdraw-mainnet \
	anvil account-sepolia account-mainnet

DEFAULT_ANVIL_KEY := 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80

build:; forge build

test:; forge test

# --- Per-network flags (set via target-specific variables below) ---
ANVIL_ARGS   := --rpc-url anvil --account $(ANVIL_ACCOUNT) --sender 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 --broadcast
SEPOLIA_ARGS := --rpc-url sepolia --account $(SEPOLIA_ACCOUNT) --broadcast --verify --etherscan-api-key $(ETHERSCAN_API_KEY) -vvvv
MAINNET_ARGS := --rpc-url mainnet --account $(MAINNET_ACCOUNT) --broadcast --verify --etherscan-api-key $(ETHERSCAN_API_KEY) -vvvv

# Default (no suffix) = local anvil.
deploy         fund         withdraw:         NETWORK_ARGS := $(ANVIL_ARGS)
deploy-sepolia fund-sepolia withdraw-sepolia: NETWORK_ARGS := $(SEPOLIA_ARGS)
deploy-mainnet fund-mainnet withdraw-mainnet: NETWORK_ARGS := $(MAINNET_ARGS)

# --- deploy ---
deploy deploy-sepolia deploy-mainnet:
	@forge script script/DeployFundMe.s.sol:DeployFundMe $(NETWORK_ARGS)

# --- fund ---
fund fund-sepolia fund-mainnet:
	@forge script script/Interactions.s.sol:FundFundMe $(NETWORK_ARGS)

# --- withdraw ---
withdraw withdraw-sepolia withdraw-mainnet:
	@forge script script/Interactions.s.sol:WithdrawFundMe $(NETWORK_ARGS)

anvil:
	anvil

# One-time: import an encrypted keystore account (you'll be prompted for the key + a password).
account-anvil:
	cast wallet import $(ANVIL_ACCOUNT) --interactive

account-sepolia:
	cast wallet import $(SEPOLIA_ACCOUNT) --interactive

account-mainnet:
	cast wallet import $(MAINNET_ACCOUNT) --interactive
