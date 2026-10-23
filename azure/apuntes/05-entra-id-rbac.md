# 05 · Entra ID y RBAC: identidad y permisos en Azure

> Anterior: [04 · Redes: VNet y NSG](04-redes-vnet-y-nsg.md) · Siguiente: *(pendiente)*
> Lab que lo acompaña: [labs/05-entra-id-y-rbac](../labs/05-entra-id-y-rbac/)

El apunte anterior iba de **por dónde se llega** a un recurso. Este va de **quién eres y qué puedes
hacer** una vez llegas. Son las dos puertas que cruza cualquier petición en Azure, y juntas son una
parte grande del AZ-104.

## 1. Entra ID y RBAC: dos cosas distintas

- **Microsoft Entra ID** es el directorio: dice **quién eres**. Ahí viven los usuarios, los grupos y
  las identidades de las aplicaciones.
- **Azure RBAC** dice **qué puedes hacer** sobre los recursos. Según la documentación, *"an
  authorization system built on Azure Resource Manager that provides fine-grained access management
  to Azure resources."*

Primero Entra ID te reconoce (autenticación) y después RBAC decide (autorización). Es la misma
pareja que en una API: el login y el `[Authorize]`.

## 2. Un permiso son tres piezas

| Pieza | Pregunta | Ejemplos |
|---|---|---|
| **Security principal** | ¿quién? | un usuario, un grupo, una identidad de aplicación |
| **Role definition** | ¿qué puede hacer? | Reader, Contributor, Owner |
| **Scope** (ámbito) | ¿dónde? | la suscripción, un grupo de recursos, un recurso |

Juntar las tres es una **asignación de rol**. "Le doy Contributor" no es una frase completa:
**Contributor dónde.** En la suscripción entera o en un solo grupo son dos poderes muy distintos.

> **Analogía (C#).** El rol es una **interfaz** (la lista de lo que se puede llamar), el principal
> es el **objeto** que llama y el ámbito es el **namespace** donde esa interfaz vale. En Azure no se
> asignan permisos sueltos: se asigna **un rol en un sitio**.

## 3. Los ámbitos heredan hacia abajo

```
Grupo de administración  →  Suscripción  →  Grupo de recursos  →  Recurso
```

Lo que se asigna arriba vale para todo lo de abajo. Al revés, no. Por eso se asigna en el ámbito
**más bajo** que sirva.

## 4. Los permisos se suman

> *"Azure RBAC is an additive model, so your effective permissions are the sum of your role
> assignments."*

- Reader y Contributor a la vez no se pisan: vale lo de Contributor.
- **No hay rol que prohíba.** Lo que no se concede, no existe.
- No hay orden ni prioridad.

Es lo contrario de un NSG (apunte 04), que tiene reglas `Deny` y la primera que encaja manda. Son
dos modelos distintos y mezclarlos es el error típico.

## 5. Los tres roles que hay que saber

| Rol | Qué puede, según la documentación |
|---|---|
| **Owner** | *"Grants full access to manage all resources, including the ability to assign roles in Azure RBAC."* |
| **Contributor** | *"Grants full access to manage all resources, but does not allow you to assign roles in Azure RBAC..."* |
| **Reader** | *"View all resources, but does not allow you to make any changes."* |

**La diferencia entre Owner y Contributor es solo una: asignar roles.** Y no es poca cosa: quien
puede asignar roles puede dárselo todo a sí mismo. Por eso una cuenta de automatización se hace
Contributor de un grupo, nunca Owner de la suscripción.

## 6. Gestión y datos son dos listas

Una definición de rol tiene dos listas de permisos:

| Lista | Qué controla | Ejemplo |
|---|---|---|
| `actions` / `notActions` | el **recurso**: crearlo, configurarlo, borrarlo | crear una cuenta de almacenamiento |
| `dataActions` / `notDataActions` | lo de **dentro** | leer o subir un blob |

Owner y Contributor tienen todo en `actions` y **nada** en `dataActions`. Por eso se puede borrar
una cuenta de almacenamiento entera y no poder subir un fichero dentro. Para eso existe **Storage
Blob Data Contributor**: *"Read, write, and delete Azure Storage containers and blobs."*

> Ser dueño de la caja fuerte no te da la combinación. Es a propósito: administrar la
> infraestructura no debería dar acceso a los datos.

## 7. Dónde vive cada cosa al borrar

```
SUSCRIPCIÓN  →  los recursos y sus asignaciones de rol.  Se van con az group delete.
TENANT       →  usuarios, grupos, identidades.          NO se van con az group delete.
```

Un grupo o una identidad de Entra ID sobreviven al borrado del grupo de recursos y hay que
borrarlos aparte.

## 8. Qué puerta te está bloqueando

```
No contesta, timeout              →  la RED (NSG, apunte 04)
Contesta AuthorizationFailed      →  los PERMISOS (RBAC)
```

## 9. Dónde enlaza con el resto

- Con **ciberseguridad**: conceder lo mínimo es Contributor en un grupo en vez de Owner en la
  suscripción, el mismo principio que abrir un puerto solo a tu IP.
- Con **CI/CD** (Fase 1): un pipeline se identifica en Azure con una identidad de Entra ID y
  necesita un rol sobre el ámbito donde despliega.
- Con **Terraform** (Fase 2): igual, necesita permisos sobre donde va a crear cosas.