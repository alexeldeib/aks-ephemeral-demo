#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

GROUP="$1"

COLOR='\033[0;36m'
NOCOLOR='\033[0m' # No Color

PLAINTEXT="${PLAINTEXT:=}"

if [ ! -z "$PLAINTEXT" ]; then
    COLOR='\033[0m'
fi

echo ""
echo -e "${COLOR}To avoid colored output, set PLAINTEXT=y${NOCOLOR}"
echo -e "${COLOR}e.g. PLAINTEXT=y ./hack/demo.sh${NOCOLOR}"
echo ""
echo -e "${COLOR}This demo deploys an AKS cluster with ephemeral os,${NOCOLOR}"
echo -e "${COLOR}ubuntu 18.04 and containerd.          ${NOCOLOR}"
echo -e "${COLOR}You can use this command to create such a cluster: ${NOCOLOR}"
echo -e '
az group create -g "${GROUP}" -n "${GROUP}" -l ${LOCATION}
az aks create -g ${GROUP} -n ${GROUP} \
    -l ${LOCATION} \
    -c 3 \
    -k 1.17.7 \
    --node-osdisk-size 64 \
    --node-vm-size Standard_D8s_v3 \
    --network-plugin azure \
    --vm-set-type VirtualMachineScaleSets \
    --load-balancer-sku standard \
    --enable-managed-identity \
    --enable-node-public-ip \
    --aks-custom-headers "EnableEphemeralOSDisk=true,ContainerRuntime=containerd,CustomizedUbuntu=aks-ubuntu-1804"'
echo -e "${COLOR}${NOCOLOR}"
echo -e "${COLOR}Additionally, you must have kubectl installed.${NOCOLOR}"
echo -e "${COLOR}${NOCOLOR}"

echo -e "${COLOR}Provisioning resource group and AKS cluster${NOCOLOR}"

az group create -g "${GROUP}" -n "${GROUP}" -l australiaeast
az aks create -g "${GROUP}" -n "${GROUP}" \
    -l australiaeast \
    -c 3 \
    -k 1.17.7 \
    --node-osdisk-size 64 \
    --node-vm-size Standard_D8s_v3 \
    --network-plugin azure \
    --vm-set-type VirtualMachineScaleSets \
    --load-balancer-sku standard \
    --enable-managed-identity \
    --enable-node-public-ip \
    --aks-custom-headers "EnableEphemeralOSDisk=true,ContainerRuntime=containerd,CustomizedUbuntu=aks-ubuntu-1804"

az aks get-credentials -g "${GROUP}" -n "${GROUP}"

sleep 3

echo -e "${COLOR}Press any key to continue${NOCOLOR}"
read -n 1 -s -r

echo -e "${COLOR}${NOCOLOR}"
echo -e "${COLOR}Let's see what nodes we have${NOCOLOR}"
echo -e "${COLOR}${NOCOLOR}"

sleep 3

kubectl get node -o wide

sleep 3

echo -e "${COLOR}${NOCOLOR}"
echo -e "${COLOR}D-Series VMs using 18.04 and containerd. Great!${NOCOLOR}"
echo -e "${COLOR}Let's apply a sample workload and see what kind of IOPS we get${NOCOLOR}"
echo -e "${COLOR}${NOCOLOR}"

sleep 3

kubectl apply -f deploy.yaml

echo -e "${COLOR}${NOCOLOR}"
echo -e "${COLOR}Waiting for that to roll out...${NOCOLOR}"
echo -e "${COLOR}${NOCOLOR}"

kubectl rollout status deployment/demo

sleep 3

echo -e "${COLOR}${NOCOLOR}"
echo -e "${COLOR}After waiting a few seconds, we can check the log output from that container${NOCOLOR}"
echo -e "${COLOR}It should be logging the amount of IOPS our workload is using${NOCOLOR}"
echo -e "${COLOR}${NOCOLOR}"

sleep 3

NAME="$(kubectl get pod -l app=demo -o jsonpath="{.items[0].metadata.name}")"
echo "POD NAME: $NAME"

echo -e "${COLOR}Press any key to stop the logs ${NOCOLOR}"

sleep 3

kubectl logs -c monitor $NAME -f &

sleep 3

read -n 1 -s -r

pkill kubectl

echo -e "${COLOR}As we can see, this far exceeds the IOPS limit for a 64 GB disk${NOCOLOR}"
echo -e "${COLOR}This would normally be a P10, limited to 500 IOPS.${NOCOLOR}"
echo -e "${COLOR}In the demo, we're able to reach ~8-10x that number.${NOCOLOR}"
echo -e "${COLOR}We should be able to max out the VM by tuning the workload.${NOCOLOR}"
echo -e "${COLOR}This is thanks to ephemeral OS and temp disk, allowing us to max out the VM SKU limits.${NOCOLOR}"

sleep 3

echo ""
echo -e "${COLOR}Simply delete all the original manifests to cleanup.${NOCOLOR}"
echo ""

sleep 3

kubectl delete cm,deploy -l app=demo
