#!/usr/bin/env bash
# Crea la red del lab 04: VNet, dos subredes, un NSG en la subred de delante y una VM de prueba.
# Uso:  ./crear-lab.sh
# Borrar:  ./borrar-lab.sh   (o az group delete --name rg-lab04-redes --yes)
set -euo pipefail

GRUPO="rg-lab04-redes"
REGION="francecentral"
VNET="vnet-lab04"
NSG="nsg-web"
VM="vm-web"

echo "==> Grupo de recursos"
az group create --name "$GRUPO" --location "$REGION" --output none

echo "==> VNet 10.10.0.0/16 con la subred snet-web 10.10.1.0/24"
az network vnet create \
    --resource-group "$GRUPO" --name "$VNET" \
    --address-prefixes 10.10.0.0/16 \
    --subnet-name snet-web --subnet-prefixes 10.10.1.0/24 \
    --output none

echo "==> Subred snet-datos 10.10.2.0/24"
az network vnet subnet create \
    --resource-group "$GRUPO" --vnet-name "$VNET" \
    --name snet-datos --address-prefixes 10.10.2.0/24 \
    --output none

echo "==> NSG y asociacion a la subred de delante"
az network nsg create --resource-group "$GRUPO" --name "$NSG" --output none
az network vnet subnet update \
    --resource-group "$GRUPO" --vnet-name "$VNET" --name snet-web \
    --network-security-group "$NSG" --output none

echo "==> Regla: SSH solo desde mi IP publica"
MI_IP=$(curl -s https://api.ipify.org)
echo "    mi IP: $MI_IP"
az network nsg rule create \
    --resource-group "$GRUPO" --nsg-name "$NSG" \
    --name permitir-ssh-desde-mi-casa \
    --priority 100 --direction Inbound --access Allow --protocol Tcp \
    --source-address-prefixes "$MI_IP" --destination-port-ranges 22 \
    --output none

echo "==> VM de prueba (ESTO FACTURA POR HORA)"
az vm create \
    --resource-group "$GRUPO" --name "$VM" \
    --image Ubuntu2204 --size Standard_B1s \
    --vnet-name "$VNET" --subnet snet-web \
    --nsg-rule NONE \
    --admin-username azureuser --generate-ssh-keys \
    --output none

IP=$(az vm show -d -g "$GRUPO" -n "$VM" --query publicIps -o tsv)
echo
echo "Listo.  ssh azureuser@$IP"
echo "NO OLVIDES:  ./borrar-lab.sh"