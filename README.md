# Foundry Fund Me

A crowdfunding smart contract built with [Foundry](https://book.getfoundry.sh/), following the [Cyfrin Updraft](https://updraft.cyfrin.io/) Foundry Fundamentals course. Users can fund the contract with ETH (subject to a minimum USD amount enforced via a Chainlink price feed), and only the owner can withdraw the collected funds.

## Overview

The `FundMe` contract lets anyone send ETH as long as it is worth at least a minimum USD value. It uses a Chainlink `AggregatorV3Interface` price feed to convert the ETH amount to USD at funding time. The contract owner is set at deployment and is the only account allowed to withdraw.

### Features

- **Minimum funding amount**: `5 USD` (enforced on-chain via `MINIMUM_USD`).
- **Chainlink price feed conversion**: ETH → USD conversion handled by the `PriceConverter` library.
- **Owner-only withdrawals**: guarded by the `onlyOwner` modifier, reverting with the custom `FundMe__NotOwner` error.
- **Two withdrawal methods**: `withdraw()` and a gas-optimized `cheaperWithdraw()`.
- **`receive` / `fallback`**: plain ETH transfers to the contract are routed to `fund()`.
- **Multi-chain support**: `HelperConfig` selects the correct price feed per network and deploys a mock on local Anvil.

## Project Structure

```
src/
  FundMe.sol            # Main crowdfunding contract
  PriceConverter.sol    # Library for ETH/USD conversion via Chainlink
script/
  DeployFundMe.s.sol    # Deployment script
  HelperConfig.s.sol    # Network-aware config (price feed / mock)
test/
  FundMeTest.t.sol      # Unit tests
  mocks/
    MockV3Aggregator.sol # Mock Chainlink price feed for local testing
```

## Contracts

### `FundMe.sol`

Key functions:

- `fund()` — Fund the contract with ETH. Reverts if the value is worth less than `MINIMUM_USD` (5 USD).
- `withdraw()` — Owner-only. Resets funder balances and transfers the full balance to the owner.
- `cheaperWithdraw()` — Owner-only, gas-optimized variant that caches the funders array in memory.
- `getVersion()` — Returns the Chainlink price feed version.
- `getAddressToAmountFunded(address)` — Amount funded by a given address.
- `getFunders(uint256)` — Funder at a given index.
- `getOwner()` — Contract owner address.

### `PriceConverter.sol`

A library (used via `using PriceConverter for uint256`) providing:

- `getPrice(priceFeed)` — Latest ETH/USD price scaled to 18 decimals.
- `getConversionRate(ethAmount, priceFeed)` — USD value of a given ETH amount.

### `HelperConfig.s.sol`

Selects the active network configuration:

- **Sepolia (chainid 11155111)**: uses the live ETH/USD feed at `0x694AA1769357215DE4FAC081bf1f309aDC325306`.
- **Local Anvil**: deploys a `MockV3Aggregator` with `8` decimals and an initial price of `2000e8`.

## Getting Started

### Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation) (`forge`, `cast`, `anvil`)

### Install dependencies

```shell
forge install
```

### Build

```shell
forge build
```

## Usage

### Test

```shell
forge test
```

Run a single test with verbose traces:

```shell
forge test --mt testWithdrawWithASingleFunder -vvv
```

Run tests against a forked network:

```shell
forge test --fork-url $SEPOLIA_RPC_URL
```

### Format

```shell
forge fmt
```

### Gas Snapshots

```shell
forge snapshot
```

### Coverage

```shell
forge coverage
```

### Local node (Anvil)

```shell
anvil
```

## Deploy

### Local (Anvil)

`HelperConfig` automatically deploys a mock price feed on a local chain, so no extra configuration is needed:

```shell
forge script script/DeployFundMe.s.sol:DeployFundMe --rpc-url http://127.0.0.1:8545 --private-key <ANVIL_PRIVATE_KEY> --broadcast
```

### Sepolia (Testnet)

```shell
forge script script/DeployFundMe.s.sol:DeployFundMe --rpc-url $SEPOLIA_RPC_URL --private-key $PRIVATE_KEY --broadcast --verify --etherscan-api-key $ETHERSCAN_API_KEY
```

> Store secrets (RPC URLs, private keys, API keys) in a `.env` file and never commit it.

## Interacting with the Contract

After deployment, use `cast` to interact with the contract:

```shell
# Fund the contract (0.1 ETH)
cast send <FUNDME_ADDRESS> "fund()" --value 0.1ether --rpc-url <RPC_URL> --private-key <PRIVATE_KEY>

# Withdraw (owner only)
cast send <FUNDME_ADDRESS> "withdraw()" --rpc-url <RPC_URL> --private-key <PRIVATE_KEY>

# Read the owner
cast call <FUNDME_ADDRESS> "getOwner()" --rpc-url <RPC_URL>
```

## Configuration

Remappings and profiles are defined in [foundry.toml](foundry.toml):

```toml
remappings = ['@chainlink/contracts/=lib/chainlink-evm/contracts/']
```

## Acknowledgements

Built as part of the [Cyfrin Updraft — Foundry Fundamentals](https://updraft.cyfrin.io/) course.

## Documentation

- [Foundry Book](https://book.getfoundry.sh/)
- [Chainlink Data Feeds](https://docs.chain.link/data-feeds/price-feeds/addresses)
