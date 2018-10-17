#!/usr/bin/env bash

BOSH_STATE="/Users/pivotal/anthony-state/bosh"
bosh int "${BOSH_STATE}/creds.yml" --path /director_ssl/ca > "${BOSH_STATE}/ca.crt"
bosh int "${BOSH_STATE}/creds.yml" --path /jumpbox_ssh/private_key > "${BOSH_STATE}/jumpbox.key"

export BOSH_ENVIRONMENT="10.0.0.4"
export BOSH_CLIENT=admin
export BOSH_CLIENT_SECRET="$(bosh int "${BOSH_STATE}/creds.yml" --path /admin_password)"
export BOSH_CA_CERT="${BOSH_STATE}/ca.crt"
export BOSH_GW_HOST="10.0.0.4"
export BOSH_GW_USER="jumpbox"
export BOSH_GW_PRIVATE_KEY="${BOSH_STATE}/jumpbox.key"