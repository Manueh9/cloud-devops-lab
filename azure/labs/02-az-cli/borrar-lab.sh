#!/usr/bin/env bash
# Lab 02 - Borrar el grupo entero.
set -euo pipefail

GRUPO="rg-lab02-azcli"

echo "==> borrando el grupo $GRUPO (y TODO lo que contiene)"
az group delete --name "$GRUPO" --yes --no-wait

echo "--> lanzado. Comprueba en un minuto con:  az group list --output table"