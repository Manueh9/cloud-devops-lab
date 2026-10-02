# 02 · La terminal: Azure CLI

> Anterior: [01 · El andamiaje de Azure](01-el-andamiaje-de-azure.md) · Siguiente: *(pendiente)*
> Lab que lo acompaña: [labs/02-az-cli](../labs/02-az-cli/)

El portal y la CLI hablan con la misma API de Azure. No hacen cosas distintas: lo que cambia es lo
que queda después. De una sesión de clics no queda nada; de un script queda un fichero que se lee,
se versiona y se vuelve a ejecutar igual la vigésima vez.

## 1. Instalar y entrar (y el MFA)

```bash
brew update && brew install azure-cli     # macOS
az version
az login
```

La primera vez, `az login` a secas puede quedarse a medias si tu cuenta exige segundo factor:

```
AADSTS50076: ... you must use multi-factor authentication ...
No subscriptions found for <tu-correo>.
```

No es un fallo: te autenticaste, pero sin pasar el MFA, así que Azure no te deja ver las
suscripciones. Se arregla forzando el login contra tu tenant, que abre el navegador y te hace
completar el segundo factor:

```bash
az login --tenant <TENANT_ID>
az account show --output table      # ¿en qué suscripción estoy?
```

`az account show` devuelve el mismo nombre e id de suscripción que enseña el portal: la prueba de
que las dos puertas dan al mismo sitio.

## 2. La forma de los comandos

Siempre `az <servicio> [<subservicio>] <acción>`:

```
az group create ...
az storage account create ...
az storage blob upload ...
```

Las acciones se repiten en todo el árbol: `create`, `list`, `show`, `delete`. Eso permite adivinar
comandos que no se han visto nunca. `--help` funciona en cualquier nivel (`az storage --help`).

| Bandera | Para qué |
|---|---|
| `--output table` | Leerlo tú |
| `--output json` | Que lo lea un script (valor por defecto) |
| `--query "[].name"` | Filtrar el JSON (sintaxis JMESPath) |

> Analogía (C#): el árbol de `az` es un espacio de nombres. `az storage blob upload` es
> `Azure.Storage.Blobs.Upload(...)`.

## 3. Nombres únicos: dónde importa y dónde no

| Recurso | Ámbito de unicidad | En un script |
|---|---|---|
| Grupo de recursos | La suscripción | Se escribe fijo |
| Storage account | **Todo Azure** (3-24 car., minúsculas y números) | **Necesita sufijo aleatorio** |

```bash
SUFIJO=$RANDOM$RANDOM
STORAGE="stlab02${SUFIJO:0:8}"
```

Nota: por CLI, `az storage account create` crea una cuenta **StorageV2** de propósito general por
defecto, que ya tiene blobs. (En el portal, en cambio, es fácil elegir sin querer un tipo
orientado solo a archivos.)

## 4. Ser dueño no es poder leer los datos (Actions vs DataActions)

Este es el concepto central del bloque, y tiene un matiz fino que se ve mejor en la terminal que en
el portal. Ser **Owner** de la suscripción te da el plano de **gestión**, pero **no** el acceso a
los **datos**:

```
   ESTRUCTURA (gestión, "Actions")      CONTENIDO (datos, "DataActions")
   ───────────────────────────────      ────────────────────────────────
   crear la cuenta        ✅            subir un blob      ❌
   crear el contenedor    ✅            leer un blob       ❌
   configurar / borrar    ✅            listar blobs       ❌
        Owner tiene esto                   Owner NO tiene esto de serie
```

Por eso, con `--auth-mode login` (usar tu identidad), **crear el contenedor funciona** —es gestión—
pero **subir el blob falla**:

```
You do not have the required permissions needed to perform this operation.
... you may need to be assigned one of the following roles:
    "Storage Blob Data Owner"
    "Storage Blob Data Contributor"
    "Storage Blob Data Reader"
```

La frontera no está entre "recurso y contenedor", está entre **la estructura y el contenido**. En
RBAC: Owner tiene `*` en Actions, pero los DataActions son otra categoría que ni Owner trae por
defecto. Es *least privilege* de diseño: administrar la cuenta no debería implicar leer los datos
de dentro.

Se arregla dándote un rol de datos, y **solo sobre este storage** (ámbito mínimo):

```bash
SCOPE=$(az storage account show --name "$STORAGE" --resource-group "$GRUPO" --query id -o tsv)
az ad signed-in-user show --query id -o tsv | az role assignment create \
    --role "Storage Blob Data Contributor" \
    --assignee @- \
    --scope "$SCOPE"
```

Después, los comandos de datos van con `--auth-mode login`, que significa "usa mi identidad" en
lugar de una clave de la cuenta. Usar la identidad es lo correcto: una clave en un script acaba, antes
o después, dentro de un repositorio. La asignación **tarda unos segundos en propagar**: el primer
comando posterior puede fallar y funcionar al repetir (por eso el script hace `sleep 30`).

## 5. Borrar

```bash
az group delete --name rg-lab02-azcli --yes --no-wait
```

`--yes` evita la confirmación interactiva y `--no-wait` devuelve el control enseguida mientras Azure
borra por detrás; justo después el grupo puede aparecer como `Deleting`.