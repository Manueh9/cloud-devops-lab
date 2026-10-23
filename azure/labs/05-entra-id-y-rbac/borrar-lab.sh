#!/usr/bin/env bash
# SIN PROBAR: escrito a partir de la documentacion oficial, no ejecutado contra Azure.
# Borra el lab 05. Son DOS limpiezas en dos sitios distintos:
#   - los grupos de recursos viven en la SUSCRIPCION  -> az group delete
#   - el grupo de Entra ID vive en el TENANT          -> az group delete NO lo toca
set -euo pipefail

GRUPO="rg-lab05-identidad"
GRUPO2="rg-lab05-vecino"
GRUPO_ENTRA="grp-lab05-equipo"

echo "==> Grupos de recursos (se llevan la cuenta y las asignaciones de rol de dentro)"
az group delete --name "$GRUPO"  --yes --no-wait || true
az group delete --name "$GRUPO2" --yes --no-wait || true

echo "==> Grupo de Entra ID"
az ad group delete --group "$GRUPO_ENTRA" || true

echo "==> Comprobacion"
az group list --output table
az ad group list --display-name "$GRUPO_ENTRA" --output table