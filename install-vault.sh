#!/bin/bash

###########################################
#
#   Hashicorp Vault Setup
#
###########################################
set -e

export VAULT_ADDR='http://0.0.0.0:8200'
export VAULT_KV_ENGINE=1
export VAULT_SECRETS_PATH=v1
export VAULT_AUTH_USER=bedu
export VAULT_AUTH_PASS=secret
export VAULT_CONTAINER=vault-rbac

echo "Vault init..."
docker exec -it $VAULT_CONTAINER vault operator init -key-shares=6 -key-threshold=3 -address=${VAULT_ADDR} > keys.txt

export VAULT_TOKEN=$(grep 'Initial Root Token:' keys.txt | awk '{print substr($NF, 1, length($NF))}')

echo "Unseal..."

TOKEN1=$(grep 'Key 1:' keys.txt | awk '{print $NF}')
TOKEN2=$(grep 'Key 2:' keys.txt | awk '{print $NF}')
TOKEN3=$(grep 'Key 3:' keys.txt | awk '{print $NF}')

echo "Token 1..."
docker exec -it vault-rbac vault operator unseal $TOKEN1

echo "Token 2..."
docker exec -it vault-rbac vault operator unseal TOKEN2

echo "Token 3..."
docker exec -it vault-rbac vault operator unseal $TOKEN3

echo "Login..."
docker exec -it vault-rbac vault login $Token

echo "Enable kv..."
docker exec -it vault-rbac vault secrets enable -version=${VAULT_KV_ENGINE} kv

echo "Enable userpass..."
docker exec -it vault-rbac vault auth enable userpass

echo "Enable approle..."
docker exec -it vault-rbac vault auth enable approle

echo "Enable kv engine..."
docker exec -it vault-rbac vault secrets enable -version=${VAULT_KV_ENGINE} -path=${VAULT_SECRETS_PATH} kv

echo "Add userpass admin..."
export POLICY_ADMIN_VAULT_HCL=/vault/policies/admin-vault.hcl

echo "Write admin policy..."
docker exec -it vault-rbac vault policy write admin-vault $POLICY_ADMIN_VAULT_HCL

echo "Create users with policy..."
docker exec -it vault-rbac vault write auth/userpass/users/${VAULT_AUTH_USER} policies=admin-vault password=${VAULT_AUTH_PASS}

#vault write auth/approle/role/user_123456789 secret_id_ttl=10m token_num_uses=10 token_ttl=20m token_max_ttl=30m secret_id_num_uses=40 policies=user_123456789
