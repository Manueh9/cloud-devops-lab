#!/usr/bin/env bash
# SIN PROBAR: escrito a partir de la documentacion oficial, no ejecutado contra Azure.
# Monta el lab 05: dos grupos de recursos, una cuenta de almacenamiento y un grupo de Entra ID
# al que se le asignan tres roles en tres ambitos distintos.
# Uso:     ./crear-lab.sh
# Borrar:  ./borrar-lab.sh   <-- borra los grupos de recursos Y el grupo de Entra ID
set -euo pipefail

GRUPO="rg-lab05-identidad"
GRUPO2="rg-lab05-vecino"
REGION="francecentral"
GRUPO_ENTRA="grp-lab05-equipo"
CUENTA="stlab05$RANDOM"   # el nombre de un storage es unico en todo Azure

SUSCRIPCION=$(az account show --query id -o tsv)
AMBITO_RG="/subscriptions/$SUSCRIPCION/resourceGroups/$GRUPO"

echo "==> Grupos de recursos (el segundo, vacio a proposito)"
az group create --name "$GRUPO"  --location "$REGION" --output none
az group create --name "$GRUPO2" --location "$REGION" --output none

echo "==> Cuenta de almacenamiento: $CUENTA"
az storage account create --name "$CUENTA" --resource-group "$GRUPO" \
    --location "$REGION" --sku Standard_LRS --output none
AMBITO_CUENTA=$(az storage account show --name "$CUENTA" --resource-group "$GRUPO" --query id -o tsv)

echo "==> Grupo de Entra ID (vive en el tenant, NO en el grupo de recursos)"
az ad group create --display-name "$GRUPO_ENTRA" --mail-nickname "$GRUPO_ENTRA" --output none
ID_GRUPO=$(az ad group show --group "$GRUPO_ENTRA" --query id -o tsv)

echo "==> Escalon 2: Reader sobre el grupo de recursos"
az role assignment create --assignee-object-id "$ID_GRUPO" --assignee-principal-type Group \
    --role "Reader" --scope "$AMBITO_RG" --output none

echo "==> Escalon 3: Contributor sobre el grupo de recursos"
az role assignment create --assignee-object-id "$ID_GRUPO" --assignee-principal-type Group \
    --role "Contributor" --scope "$AMBITO_RG" --output none

echo "==> Escalon 4: Storage Blob Data Contributor solo sobre la cuenta"
az role assignment create --assignee-object-id "$ID_GRUPO" --assignee-principal-type Group \
    --role "Storage Blob Data Contributor" --scope "$AMBITO_CUENTA" --output none

echo
echo "Asignaciones del grupo $GRUPO_ENTRA:"
az role assignment list --all --assignee "$ID_GRUPO" \
    --query "[].{Rol:roleDefinitionName, Ambito:scope}" --output table
echo
echo "NO OLVIDES:  ./borrar-lab.sh"