#!/usr/bin/env bash

set -ex

CFB_HOME="/Users/pivotal/workspace/cfdev-builder/create-state-ci"
DEPS="${CFB_HOME}/deps"
OUTPUT="${CFB_HOME}/output/cache"

STATE_DIR="/Users/pivotal/anthony-state"
LINUXKIT_STATE="${STATE_DIR}/linuxkit"
VPNKIT_STATE="${STATE_DIR}/vpnkit"
VPNKIT_ETH_SOCK="${STATE_DIR}/vpnkit/vpnkit_eth.sock"
VPNKIT_PORT_SOCK="${STATE_DIR}/vpnkit/vpnkit_port.sock"
BOSH_STATE="${STATE_DIR}/bosh"

BOSH_DEPLOYMENT_DIR="/Users/pivotal/workspace/bosh-deployment"
CF_DEPLOYMENT_DIR="/Users/pivotal/workspace/cf-deployment"

STEMCELL_VERSION="3586.42"
DOCKER_REGISTRIES='["host.cfdev.sh:5000"]'
HOST_IP="192.168.65.1"
CF_DOMAIN="dev.cfdev.sh"
 
# SETUP NETWORK ALIASES
# sudo ifconfig lo0 alias 10.0.0.4 #bosh director
# sudo ifconfig lo0 alias 10.0.0.5 #cf router

rm -rf ${STATE_DIR}
mkdir -p ${STATE_DIR}

${DEPS}/linuxkit run hyperkit \
  -console-file \
  -iso \
  -uefi \
  -cpus=4 \
  -mem=4096 \
  -disk "type=qcow,size=40G,trim=true,qcow-tool=${DEPS}/qcowtool,qcow-onflush=os,qcow-compactafter=262144,qcow-keeperased=262144" \
  -hyperkit ${DEPS}/hyperkit \
  -networking vpnkit \
  -fw ${DEPS}/UEFI-udk2014.sp1.fd \
  -state ${LINUXKIT_STATE} \
  -publish 9999:9999/tcp \
  -publish 9998:9998/tcp \
  "${DEPS}/bosh-lit-efi.iso" > /tmp/linukit.log 2>&1 &

echo "wait till the VM is up ... "
echo "wait till the VM is up ... "
echo "wait till the VM is up ... "
sleep 30
echo "DONE WAITING .........."
echo "DONE WAITING .........."
echo "DONE WAITING .........."

#GENERATE BOSH MANIFEST
./scripts/generate-bosh-manifest -b ${BOSH_DEPLOYMENT_DIR} -s ${STEMCELL_VERSION}

#DEPLOY BOSH DIRECTOR
bosh --tty create-env \
  "${BOSH_DEPLOYMENT_DIR}/director.yml" \
  --state "${BOSH_STATE}/state.json" \
  --vars-store "${BOSH_STATE}/creds.yml"

# EARLY EXIT
exit 0

#SET BOSH ENVs
source ${CFB_HOME}/set-bosh-env.sh

#GENERATE CF MANIFEST
./scripts/generate-cf-manifest -c ${CF_DEPLOYMENT_DIR}

#UPDATE CLOUD CONFIG
bosh -n update-cloud-config "${OUTPUT}"/cloud-config.yml

#UPDATE BOSH DNS
bosh -n update-runtime-config "${OUTPUT}"/dns.yml --name=dns \
  -v host_ip="${HOST_IP}" \
  --vars-store "${CF_DEPLOYMENT_DIR}/vars.yml"

bosh -n upload-stemcell ${DEPS}/bosh-stemcell-3586.42-warden-boshlite-ubuntu-trusty-go_agent.tgz

#DEPLOY CLOUD FOUNDRY
bosh --tty --non-interactive --deployment cf \
  deploy "${OUTPUT}/deployment.yml" \
  -v system_domain="${CF_DOMAIN}" \
  -v insecure_docker_registries="${DOCKER_REGISTRIES}" \
  --vars-store "${CF_DEPLOYMENT_DIR}/vars.yml"

## TODO need to prune hard disk before shipping...