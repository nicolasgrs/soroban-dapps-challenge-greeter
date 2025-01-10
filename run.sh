#!/usr/bin/env bash
set -e

echo "========================================="
echo " Pulling esteblock/soroban-preview:22.0.1"
echo "========================================="
docker pull esteblock/soroban-preview:22.0.1

echo "========================================="
echo " Starting interactive container"
echo "========================================="
docker run -it --rm \
  -v "$(pwd)":/app \
  -w /app \
  --name soroban-greeter \
  esteblock/soroban-preview:22.0.1 \
  bash