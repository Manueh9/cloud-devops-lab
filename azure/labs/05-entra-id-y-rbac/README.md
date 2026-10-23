# Lab 05 · Entra ID y RBAC: quién puede hacer qué, y dónde

> Anterior: [lab 04 · VNet y NSG](../04-vnet-y-nsg/)
> Teoría: [apuntes/05-entra-id-rbac.md](../../apuntes/05-entra-id-rbac.md)

> 📘 **Lab teórico.** Los comandos son los reales y reproducibles, pero no se han ejecutado en esta
> cuenta. Lo que aparece como **salida esperada** es lo que la documentación oficial de Azure dice
> que debe ocurrir; no es una salida copiada de una terminal.

## Objetivo

Dar a un grupo de Entra ID tres roles en tres ámbitos distintos y entender qué puede hacer un
miembro en cada escalón. El lab va de tres ideas:

1. Un permiso en Azure son **tres piezas**: quién, qué rol y **dónde** (el ámbito).
2. Los permisos **se suman**. No hay rol que prohíba: lo que no se concede, no existe.
3. **Gestión y datos son dos listas distintas.** Se puede administrar una cuenta de almacenamiento
   sin poder leer un fichero de dentro.

## Ficheros

| Fichero | Para qué |
|---|---|
| [`crear-lab.sh`](crear-lab.sh) | Crea los grupos, la cuenta, el grupo de Entra ID y las tres asignaciones |
| [`borrar-lab.sh`](borrar-lab.sh) | Borra los grupos de recursos **y** el grupo de Entra ID, que no se va con ellos |

Los dos están escritos a partir de la documentación oficial y **sin probar contra Azure**; la
sintaxis está comprobada con `bash -n`.

## Lo que se monta

```
Tenant (Entra ID)
└── grp-lab05-equipo          ← el "quién". NO está dentro de ningún grupo de recursos

Suscripción
├── rg-lab05-identidad        ← aquí se asignan los roles
│   └── stlab05XXXX           (cuenta de almacenamiento)
└── rg-lab05-vecino           ← vacío a propósito: la prueba de que el ámbito es una frontera
```

## Paso 1 — Quién soy y qué roles tengo

```bash
MI_ID=$(az ad signed-in-user show --query id -o tsv)
az role assignment list --all --assignee "$MI_ID" \
    --query "[].{Rol:roleDefinitionName, Ambito:scope}" --output table
```

**Salida esperada:** en una suscripción propia, `Owner` con ámbito `/subscriptions/<id>`, es decir,
sobre la suscripción entera. Por eso puedes hacer todo el lab, incluido repartir roles.

## Paso 2 — Abrir los roles por dentro

```bash
az role definition list --name "Reader"      --query "[0].permissions[0]" --output json
az role definition list --name "Contributor" --query "[0].permissions[0]" --output json
az role definition list --name "Owner"       --query "[0].permissions[0]" --output json
az role definition list --name "Storage Blob Data Contributor" --query "[0].permissions[0]" --output json
```

**Salida esperada**, resumida:

| Rol | `actions` (gestión) | `notActions` | `dataActions` (datos) |
|---|---|---|---|
| Reader | `*/read` | ninguna | ninguna |
| Contributor | `*` | las de asignar roles (`Microsoft.Authorization`) y alguna más | ninguna |
| Owner | `*` | ninguna | ninguna |
| Storage Blob Data Contributor | unas pocas, de contenedores | — | las de leer, escribir y borrar blobs |

Fíjate en dos cosas:

- **Owner y Contributor tienen `actions: *`.** La única diferencia está en los `notActions` de
  Contributor, que le quitan asignar roles. La documentación lo dice así: Contributor *"does not
  allow you to assign roles in Azure RBAC"*.
- **Ni Owner trae `dataActions`.** Por eso ser dueño de una cuenta de almacenamiento no te deja
  subir un fichero: hace falta un rol de datos aparte.

La lista exacta de `notActions` de Contributor la va cambiando Microsoft; se comprueba con este
comando, no se aprende de memoria.

## Paso 3 — Montar el lab

```bash
./crear-lab.sh
```

**Salida esperada al final del script:** tres asignaciones para `grp-lab05-equipo`:

| Rol | Ámbito |
|---|---|
| Reader | `/subscriptions/<id>/resourceGroups/rg-lab05-identidad` |
| Contributor | `/subscriptions/<id>/resourceGroups/rg-lab05-identidad` |
| Storage Blob Data Contributor | `/subscriptions/<id>/resourceGroups/rg-lab05-identidad/providers/Microsoft.Storage/storageAccounts/stlab05XXXX` |

Dos en el grupo de recursos y una en la cuenta: el tercer ámbito es más estrecho a propósito. El
permiso de datos se da sobre el dato, no sobre la carpeta.

## Paso 4 — Qué puede hacer un miembro del grupo en cada escalón

Esto es lo que se comprobaría entrando con un usuario que pertenezca al grupo.

| Con qué roles | Qué pasa | Por qué |
|---|---|---|
| Ninguno | `az group list` sale **vacío**; `az resource list -g rg-lab05-identidad` da `AuthorizationFailed` | Lo que no se concede no existe. No ver algo no es un error, es que no aparece |
| Reader en el grupo | Ve el grupo y la cuenta; crear cualquier cosa da `AuthorizationFailed` | *"View all resources, but does not allow you to make any changes."* |
| + Contributor | Crea y borra recursos en el grupo; **asignar un rol** da `AuthorizationFailed` | Los `notActions` del paso 2 |
| Contributor, sin rol de datos | Crea un contenedor; **subir un blob** con `--auth-mode login` falla | Contributor no tiene `dataActions` |
| + Storage Blob Data Contributor | Sube y lee blobs de **esa** cuenta | Ahora sí tiene las `dataActions` |
| Cualquiera de los anteriores, en `rg-lab05-vecino` | No ve nada | Ningún ámbito llega ahí. Nadie lo ha prohibido: no se ha concedido |

Y una que confunde: **Reader y Contributor a la vez no se pisan.** Los permisos se suman, así que el
efectivo es el de Contributor. Según la documentación, *"your effective permissions are the sum of
your role assignments"*.

## Paso 5 — Borrar

```bash
./borrar-lab.sh
```

**Salida esperada:** ni `rg-lab05-identidad` ni `rg-lab05-vecino` en `az group list`, y
`az ad group list --display-name grp-lab05-equipo` vacío.

El script hace **dos** borrados porque el grupo de Entra ID **vive en el tenant, no en la
suscripción**. `az group delete` se lleva la cuenta y las asignaciones de rol que había dentro, pero
el grupo de Entra ID se queda. Es el mismo patrón que la NIC y la IP pública del lab 04: borrar lo
que ves no borra todo lo que creaste.

## Lo que hay que llevarse

```
un permiso = QUIÉN + QUÉ ROL + DÓNDE
ámbitos: grupo de administración → suscripción → grupo de recursos → recurso
lo asignado arriba vale abajo; al revés, no
los permisos SUMAN · no hay rol que prohíba · no hay orden (al revés que un NSG)
Owner = Contributor + asignar roles
actions = el recurso · dataActions = lo de dentro · ni Owner trae dataActions
lo de Entra ID no se borra con az group delete
```

## Qué queda pendiente a propósito

- **Roles personalizados** escritos en JSON. Primero, los integrados.
- **Service principals e identidades administradas**: las identidades para programas. Entran en la
  Fase 1, cuando un pipeline tenga que desplegar en Azure.
- **Deny assignments y Azure Policy**: la única forma de prohibir, que no es un rol.
- **Privileged Identity Management**: acceso temporal, de empresa grande.

## Fuentes

- [Qué es Azure RBAC](https://learn.microsoft.com/en-us/azure/role-based-access-control/overview): las tres piezas, los cuatro ámbitos y el modelo aditivo.
- [Roles integrados](https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles): Owner, Contributor, Reader y Storage Blob Data Contributor.
- [Referencia de `az role assignment`](https://learn.microsoft.com/en-us/cli/azure/role/assignment)