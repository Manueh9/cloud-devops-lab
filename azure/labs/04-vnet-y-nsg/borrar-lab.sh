#!/usr/bin/env bash
# Borra el grupo entero del lab 04. Es la unica limpieza fiable: borrar la VM deja
# viva su tarjeta de red y su IP publica, y la IP publica sigue facturando.
set -euo pipefail

GRUPO="rg-lab04-redes"

echo "==> Borrando $GRUPO (y todo lo de dentro)"
az group delete --name "$GRUPO" --yes --no-wait

echo "==> Grupos que quedan:"
az group list --output table