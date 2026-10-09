#!/usr/bin/env bash
# Borra el grupo entero del lab 03.
# Sin --no-wait a proposito: bloquea hasta terminar, para que el ciclo
# borrar -> desplegar funcione sin chocar con un grupo a medio borrar.
set -euo pipefail

GRUPO="rg-lab03-appservice"

echo "==> Borrando $GRUPO (tarda unos minutos, es lo que se quiere)"
az group delete --name "$GRUPO" --yes

echo
echo "==> Grupos que quedan:"
az group list --output table

echo
echo "==> Planes que quedan (lo que factura es el PLAN, no la app):"
az appservice plan list --output table
