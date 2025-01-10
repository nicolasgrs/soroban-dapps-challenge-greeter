EXAMPLE_USER_SECRET="$(soroban keys show example-user)"
NETWORK="$(cat ./.soroban-example-dapp/network)"
CONTRACT_ID="$(cat ./.soroban/hello_world_id)"

soroban contract invoke \
    --network $NETWORK \
    --source-account $EXAMPLE_USER_SECRET \
    --id $CONTRACT_ID \
    -- \
    hello \
    --to "Alice"
