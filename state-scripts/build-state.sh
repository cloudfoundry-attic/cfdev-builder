#!/usr/bin/env bash


STATE_DIR="state"
QCOW_TOOL="deps/qcow-tool"
EFI="bosh-lit-efi.iso"
LINUXKIT_STATE="${STATE_DIR}/linuxkit"
DIRECTOR_DIR="${STATE_DIR}/director"
BOSH_DEPLOYMENT_DIR="/Users/pivotal/workspace/bosh-deployment"
RUNC_CPI_DIR="/Users/pivotal/workspace/bosh-runc-cpi-release"
STEM_CELL_VERSION="3586.42"
BOSH_EFI="deps/bosh-lit-efi.iso"

#cleanup/check state
#kill $(ps -ef | grep hyperkit | awk '{print $2}')
#kill $(ps -ef | grep vpnkit | awk '{print $2}')
rm ${LINUXKIT_STATE}/*

#build CPI RELEASE
pushd ${RUNC_CPI_DIR}
  bosh vendor-package golang-1.10-darwin ~/workspace/golang-release
  bosh vendor-package golang-1.10-linux ~/workspace/golang-release
  bosh create-release --force --sha2 --tarball=/tmp/cpi.tgz
popd

#network
sudo ifconfig lo0 alias 10.0.0.4 #bosh director
sudo ifconfig lo0 alias 10.0.0.5 #cf router

#build bosh-lit-efi.iso HERE
#-disk "type=qcow,size=80G,trim=true,qcow-tool=${QCOW_TOOL},qcow-onflush=os,qcow-compactafter=262144,qcow-keeperased=262144" \

#start linuxkit
linuxkit run hyperkit \
-console-file \
-iso \
-uefi \
-cpus=4 \
-mem=10000 \
-disk size=65G \
-networking vpnkit \
-publish 9999:9999/tcp \
-publish 9998:9998/tcp \
-state ${LINUXKIT_STATE} \
${BOSH_EFI} &

echo "wait till the VM is up ... "
echo "wait till the VM is up ... "
echo "wait till the VM is up ... "
sleep 180
echo "DONE WAITING .........."
echo "DONE WAITING .........."
echo "DONE WAITING .........."

#generate bosh manifest
./generate-bosh-manifest -b ${BOSH_DEPLOYMENT_DIR} -s ${STEM_CELL_VERSION}

#deploy director
bosh --tty create-env \
  "./../output/cache/director.yml" \
  --vars-store="${DIRECTOR_DIR}/creds.yml" \
  --state="${DIRECTOR_DIR}/state.json" \

bosh int "${DIRECTOR_DIR}/creds.yml" \
  --path /director_ssl/ca > "${DIRECTOR_DIR}/ca.crt"

bosh int "${DIRECTOR_DIR}/creds.yml" \
  --path /jumpbox_ssh/private_key > "${DIRECTOR_DIR}/jumpbox.key"

cat <<EOF > "${DIRECTOR_DIR}/env"
export BOSH_ENVIRONMENT="${BOSH_DIRECTOR_IP}"
export BOSH_CLIENT=admin
export BOSH_CLIENT_SECRET=$(bosh int "${DIRECTOR_DIR}/creds.yml" --path /admin_password)
export BOSH_CA_CERT="$(cat ${DIRECTOR_DIR}/ca.crt)"
EOF

#upload stuff



