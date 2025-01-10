#!/bin/bash

set -e

NETWORK="$1"

SOROBAN_RPC_HOST="$2"

if [[ "$SOROBAN_RPC_HOST" == "" ]]; then
  if [[ "$NETWORK" == "futurenet" ]]; then
    SOROBAN_RPC_HOST="https://rpc-futurenet.stellar.org:443"
    SOROBAN_RPC_URL="$SOROBAN_RPC_HOST"
  elif [[ "$NETWORK" == "testnet" ]]; then
    SOROBAN_RPC_HOST="https://soroban-testnet.stellar.org:443"
    SOROBAN_RPC_URL="$SOROBAN_RPC_HOST"
  fi
else
  SOROBAN_RPC_URL="$SOROBAN_RPC_HOST"
fi

case "$1" in
futurenet)
  echo "Using Futurenet network with RPC URL: $SOROBAN_RPC_URL"
  SOROBAN_NETWORK_PASSPHRASE="Test SDF Future Network ; October 2022"
  FRIENDBOT_URL="https://friendbot-futurenet.stellar.org/"
  ;;
testnet)
  echo "Using Testnet network with RPC URL: $SOROBAN_RPC_URL"
  SOROBAN_NETWORK_PASSPHRASE="Test SDF Network ; September 2015"
  FRIENDBOT_URL="https://friendbot.stellar.org/"
  ;;
*)
  echo "Usage: $0 futurenet|testnet [rpc-host]"
  exit 1
  ;;
esac

echo Add the $NETWORK network to cli client
soroban network add "$NETWORK" \
  --rpc-url "$SOROBAN_RPC_URL" \
  --network-passphrase "$SOROBAN_NETWORK_PASSPHRASE"

echo Add $NETWORK to .soroban for use with npm scripts
mkdir -p .soroban
mkdir -p .soroban-example-dapp
echo $NETWORK >./.soroban-example-dapp/network
echo $SOROBAN_RPC_URL >./.soroban-example-dapp/rpc-url
echo "$SOROBAN_NETWORK_PASSPHRASE" >./.soroban-example-dapp/passphrase
echo "{ \"network\": \"$NETWORK\", \"rpcUrl\": \"$SOROBAN_RPC_URL\", \"networkPassphrase\": \"$SOROBAN_NETWORK_PASSPHRASE\" }" >./shared/config.json

if !(soroban keys ls | grep example-user 2>&1 >/dev/null); then
  echo Create the example-user identity
  soroban keys generate example-user --network "$NETWORK" \
    --rpc-url "$SOROBAN_RPC_URL" \
    --network-passphrase "$SOROBAN_NETWORK_PASSPHRASE"
fi

EXAMPLE_USER_ADDRESS="$(soroban keys address example-user)"
echo $EXAMPLE_USER_ADDRESS >./.soroban-example-dapp/address

EXAMPLE_USER_SECRET="$(soroban keys show example-user)"
echo $EXAMPLE_USER_SECRET >./.soroban-example-dapp/secret

# This will fail if the account already exists, but it'll still be fine.
echo Fund example-user account from friendbot
curl --silent -X POST "$FRIENDBOT_URL?addr=$EXAMPLE_USER_ADDRESS" >/dev/null

ARGS="--network $NETWORK --source example-user"

echo Build contracts
soroban contract build

echo Optimizing the hello world contract
soroban contract optimize --wasm target/wasm32-unknown-unknown/release/soroban_modified_hello_world_contract.wasm

echo Deploy the hello world contract

HELLO_WORLD_ID="$(
  soroban contract deploy $ARGS \
    --wasm target/wasm32-unknown-unknown/release/soroban_modified_hello_world_contract.optimized.wasm
)"

echo "Contract deployed succesfully with ID: $HELLO_WORLD_ID"
echo "$HELLO_WORLD_ID" >.soroban/hello_world_id

echo "Done"
