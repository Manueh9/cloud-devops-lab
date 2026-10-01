# Lab 01 · Primer grupo de recursos (portal)

> Teoría: [apuntes/01-el-andamiaje-de-azure.md](../../apuntes/01-el-andamiaje-de-azure.md)
> Siguiente: *(pendiente)*

## Objetivo

Recorrer a mano, en el portal, la jerarquía completa de Azure: crear un grupo de recursos, meter
un recurso dentro, comprobar que el acceso es privado por defecto, ver dónde se consulta el gasto,
poner una alerta y **borrarlo todo con una sola acción**.

Es deliberadamente manual. La versión repetible con `az` es el lab 02; hacerlo primero a clics es
lo que permite entender después qué está haciendo el script.

## Antes de empezar

- Una cuenta de Azure activa.
- Nada más: este lab no necesita ninguna herramienta instalada.

## Pasos

1. **Localizar la suscripción.** Portal → *Suscripciones*. Anotar su nombre.
2. **Crear el grupo de recursos.** *Grupos de recursos* → *+ Crear* → nombre `rg-lab01-azure`,
   región `France Central`. Crear un grupo no cuesta nada.
3. **Crear un Storage Account dentro.** *Cuentas de almacenamiento* → *+ Crear* → el grupo del
   paso 2, servicio principal **Azure Blob Storage**, rendimiento Estándar, redundancia LRS, un
   nombre único de 3-24 caracteres en minúsculas y números.
4. **Subir un blob.** Dentro del storage → *Contenedores* → *+ Contenedor* (`pruebas`) → *Cargar*.
5. **Comprobar que es privado.** Copiar la URL del blob y abrirla en una ventana de incógnito:
   devuelve error de autorización.
6. **Ver el gasto.** Suscripción → *Administración de costos* → *Análisis de costos*.
7. **Poner una alerta.** Suscripción → *Presupuestos* → importe bajo, aviso al 80 % del coste real.
8. **Borrar el grupo.** *Grupos de recursos* → *Eliminar grupo de recursos*. Se va todo con él.

## Resultado

| Dato | Valor |
|---|---|
| Región | `francecentral` |
| Grupo de recursos | `rg-lab01-azure` |
| Storage account | `stlab01manueh10` |
| Contenedor | `pruebas` |
| URL del blob | `https://stlab01manueh10.blob.core.windows.net/pruebas/fichero.txt` |
| Qué devolvió la URL en incógnito | `PublicAccessNotPermitted` — *"Public access is not permitted on this storage account."* |
| Análisis de costos antes de borrar | 0,00 € — *"No se ha notificado ningún costo durante este período"* |
| Presupuesto creado | `presupuesto-mensual`, 5 €/mes, alerta al 80 % del coste real → mi correo |
| Grupos que quedan tras el borrado | `rg-lab01-azure` ya no aparece |

## Errores con los que me topé

1. **`RequestDisallowedByAzure` al crear el storage en West Europe** — *"The selected region is
   currently not accepting new customers"*. La región estaba saturada; cambié a France Central y
   funcionó.
2. **Elegí mal el tipo de cuenta.** Puse *Azure Files* como servicio principal, así que la cuenta
   quedó como FileStorage y no tenía contenedores de blob (no salía "Contenedores"). La borré y la
   rehíce como *Azure Blob Storage*. Coste cero — la lección de por qué cada lab va en su grupo.

## Qué queda pendiente a propósito

- **La redundancia** (LRS / ZRS / GRS) se eligió sin entrar en el tema. Pertenece a alta
  disponibilidad, no a este lab.
- **Hacer el blob público** no se prueba: además del contenedor, la cuenta trae el acceso anónimo
  deshabilitado, y activarlo es una decisión de seguridad que merece su propio apunte.
- **Todo esto a mano** es justo lo que arregla el lab 02: los mismos recursos desde la terminal,
  en un script que se puede repetir y borrar sin abrir el navegador.