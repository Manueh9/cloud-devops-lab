#!/usr/bin/env bash
# Lab 02 - Crear el grupo, un storage account, un contenedor y subir un blob.
# Todo dentro de UN grupo de recursos, para borrarlo de una vez con borrar-lab.sh.
set -euo pipefail

GRUPO="rg-lab02-azcli"
REGION="francecentral"
CONTENEDOR="pruebas"

# El nombre del storage es unico en TODO Azure: 3-24 caracteres, minusculas y numeros.
# Por eso lleva sufijo aleatorio.
SUFIJO=$RANDOM$RANDOM
STORAGE="stlab02${SUFIJO:0:8}"

echo "==> Grupo:   $GRUPO ($REGION)"
echo "==> Storage: $STORAGE"

echo "--> creando el grupo de recursos"
az group create --name "$GRUPO" --location "$REGION" --output table

echo "--> creando el storage account (StorageV2 por defecto: con blobs)"
az storage account create \
    --name "$STORAGE" \
    --resource-group "$GRUPO" \
    --location "$REGION" \
    --sku Standard_LRS \
    --encryption-services blob \
    --output table

echo "--> dandome el rol de DATOS sobre este storage (ser dueño no basta)"
SCOPE=$(az storage account show --name "$STORAGE" --resource-group "$GRUPO" --query id -o tsv)
az ad signed-in-user show --query id -o tsv | az role assignment create \
    --role "Storage Blob Data Contributor" \
    --assignee @- \
    --scope "$SCOPE" \
    --output none

echo "--> esperando a que el rol propague"
sleep 30

echo "--> creando el contenedor"
az storage container create \
    --account-name "$STORAGE" \
    --name "$CONTENEDOR" \
    --auth-mode login \
    --output table

echo "--> subiendo un fichero"
echo "hola desde la terminal, $(date)" > prueba.txt
az storage blob upload \
    --account-name "$STORAGE" \
    --container-name "$CONTENEDOR" \
    --name prueba.txt \
    --file prueba.txt \
    --auth-mode login \
    --output table

echo "--> lo que hay dentro del contenedor:"
az storage blob list \
    --account-name "$STORAGE" \
    --container-name "$CONTENEDOR" \
    --auth-mode login \
    --output table

echo
echo "LISTO. Para borrarlo todo:  ./borrar-lab.sh"