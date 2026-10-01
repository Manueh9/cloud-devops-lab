# 01 · El andamiaje de Azure: suscripción, grupo de recursos y recurso

> Anterior: *(primer apunte de Azure; vienes de [Docker](../../docker/))* · Siguiente: *(pendiente)*
> Lab que lo acompaña: [labs/01-primer-grupo-de-recursos](../labs/01-primer-grupo-de-recursos/)

Antes de desplegar nada en Azure hay que entender dónde se guardan las cosas. Azure no es una
carpeta gigante: es una jerarquía de cuatro cajas, y saber qué hace cada una evita los dos errores
clásicos del principiante — no encontrar lo que creaste, y no poder apagarlo.

## 1. Las cuatro cajas

```
TENANT (Microsoft Entra ID)     ← quién eres y quién puede entrar
 └── SUSCRIPCIÓN                ← quién paga; el límite de facturación
      └── GRUPO DE RECURSOS     ← la carpeta; la unidad de borrado
           └── RECURSO          ← la cosa concreta: un storage, una web app, una BD
```

| Caja | Qué es | Cuesta dinero |
|---|---|---|
| Tenant | La identidad: usuarios, grupos, permisos | No |
| Suscripción | El contenedor de facturación | No por sí misma |
| Grupo de recursos | Una agrupación lógica dentro de una suscripción | **No** |
| Recurso | El servicio real que se ejecuta o almacena | **Sí** |

Que el grupo de recursos sea gratis es lo que permite tener uno por experimento sin pensárselo.

> **Analogía (.NET).** La suscripción es la solución (`.sln`), el grupo de recursos es el proyecto
> (`.csproj`) y el recurso es la clase. Borrar el proyecto se lleva por delante todas sus clases.

## 2. La región

Cada recurso se crea en una región concreta: un conjunto de centros de datos con ubicación física
real. La región condiciona la latencia, el precio (el mismo recurso no cuesta igual en todas) y
—esto no es teórico— la **disponibilidad**: una región puede estar tan saturada que no admita
recursos nuevos. Me pasó: West Europe me rechazó la creación con
`RequestDisallowedByAzure` / *"The selected region is currently not accepting new customers"*, y
tuve que moverme a **France Central**. La lección: elige una región que acepte, y no la cambies
dentro del mismo trabajo. Recursos repartidos por regiones son recursos que se olvidan.

## 3. El grupo de recursos es la unidad de borrado

Es la propiedad que más se usa en el día a día. Borrar un grupo borra **todo** lo que contiene, de
una vez:

```bash
az group delete --name rg-lab01-azure --yes --no-wait
```

De ahí sale la regla de trabajo de esta carpeta:

> **Un lab = un grupo de recursos = un borrado al terminar.**

> **Analogía (C#).** El grupo de recursos es un bloque `using`: lo que nace dentro muere al salir.
> La diferencia es que aquí el `Dispose()` lo llamas tú, y si se te olvida, el objeto sigue vivo
> y facturando.

## 4. Nombres globalmente únicos

Algunos recursos tienen nombres que son **únicos en todo Azure**, no solo en tu cuenta. El caso
más común es el Storage Account:

> *"Storage account names must be between 3 and 24 characters in length. They can contain only
> numbers and lowercase letters. Your storage account name must be unique within Azure."*

El motivo es que el nombre se convierte en una dirección pública:
`https://<nombre>.blob.core.windows.net`. Es la misma lógica que un dominio o un paquete de NuGet:
global, y de quien llega primero. Un grupo de recursos, en cambio, solo tiene que ser único dentro
de la suscripción.

## 5. Lo privado por defecto

Un contenedor de blobs recién creado **no es público**. Al abrir la URL del blob desde una ventana
sin sesión, Azure devolvió:

```xml
<Error>
  <Code>PublicAccessNotPermitted</Code>
  <Message>Public access is not permitted on this storage account.</Message>
</Error>
```

El matiz importante: no es solo que el contenedor sea privado, es que **la cuenta entera trae el
acceso público anónimo deshabilitado** por defecto. Doble candado: aunque marcara un contenedor
como público, la cuenta lo seguiría bloqueando. Que algo esté "en la nube" no significa que
cualquiera pueda leerlo: el acceso se concede explícitamente.

## 6. El gasto: dónde se mira y cómo se avisa

- **Análisis de costos** (en la suscripción, sección *Administración de costos*) muestra el
  consumo. Lo agrega con horas de retraso; en una cuenta recién estrenada dice directamente
  *"No se ha notificado ningún costo durante este período"*.
- **Presupuestos** permite fijar un importe y avisar por correo al superar un porcentaje. Conviene
  ponerlo bajo a propósito: un presupuesto que nunca salta no protege de nada.
- Una suscripción recién creada necesita 48 horas antes de admitir presupuestos.
- La cuenta gratuita trae además el **límite de gasto** activado: al agotar el crédito, Azure
  apaga los recursos en vez de cobrar.

## 7. Mis cifras de este lab

| Dato | Valor |
|---|---|
| Suscripción | Azure subscription 1 |
| Región usada | `francecentral` |
| Nombre del grupo | `rg-lab01-azure` |
| Nombre del storage account | `stlab01manueh10` |
| Redundancia elegida | LRS (redundancia local) |
| Coste en Análisis de costos al terminar | 0,00 € — *"No se ha notificado ningún costo durante este período"* |
| Presupuesto | `presupuesto-mensual`, 5 €/mes, alerta al 80 % del coste real → mi correo |

## 8. Lo que costó

Dos tropiezos, los dos instructivos y los dos de coste cero:

1. **West Europe no admitía nuevos clientes.** El error (`RequestDisallowedByAzure`,
   *locationineligible*) no era culpa del nombre ni mía: la región estaba saturada. Cambié a
   France Central y pasó a la primera. Es el concepto de "región = disponibilidad" en vivo.
2. **Creé la cuenta como FileStorage por error.** Elegí *Azure Files* como servicio principal, así
   que la cuenta quedó orientada a recursos compartidos de archivos y **no tenía contenedores de
   blob** (no aparecía "Contenedores" en el menú). La borré y la rehíce como *Azure Blob Storage*
   (`stlab01manueh10`). Borrar y rehacer costó cero: justo por eso cada lab vive en su propio grupo.