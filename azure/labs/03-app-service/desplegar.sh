#!/usr/bin/env bash
# Despliega la API .NET en Azure App Service (F1) con las cuatro piezas por separado,
# que es lo que hace por dentro el comando 'az webapp up' (deprecado).
#
# Uso:     ./desplegar.sh
# Borrar:  ./borrar-lab.sh
set -euo pipefail

GRUPO="rg-lab03-appservice"
REGION="francecentral"
PLAN="plan-lab03"
APP="dockerlab-manueh-$RANDOM"
RUNTIME="DOTNETCORE|8.0"

# La app vive en app/DockerLab, tres niveles por encima de este script.
RAIZ="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
APP_DIR="$RAIZ/app/DockerLab"

echo "==> 1/4  Grupo de recursos: $GRUPO"
az group create --name "$GRUPO" --location "$REGION" --output none

echo "==> 2/4  Plan (la maquina, ESTO es lo que factura): $PLAN"
az appservice plan create \
    --name "$PLAN" --resource-group "$GRUPO" \
    --sku F1 --is-linux --output none

echo "==> 3/4  Web app: $APP"
az webapp create \
    --name "$APP" --resource-group "$GRUPO" --plan "$PLAN" \
    --runtime "$RUNTIME" --output none

echo "==> 4/4  Compilar AQUI y subir solo el resultado"
cd "$APP_DIR"
rm -rf ./publicar app.zip
dotnet publish -c Release -o ./publicar
(cd publicar && zip -qr ../app.zip .)
echo "    zip: $(du -h app.zip | cut -f1)"

az webapp deploy \
    --name "$APP" --resource-group "$GRUPO" \
    --src-path app.zip --type zip --output none

echo "==> Redireccion a HTTPS en el borde (la hace Azure, no la app)"
az webapp update \
    --name "$APP" --resource-group "$GRUPO" \
    --https-only true --output none

echo
echo "Listo:  https://$APP.azurewebsites.net/weatherforecast"
echo "NO OLVIDES:  ./borrar-lab.sh"
