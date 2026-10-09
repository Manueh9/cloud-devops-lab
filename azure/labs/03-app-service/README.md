# Lab 03 · La API .NET en App Service

> Anterior: [lab 02 · Los mismos recursos, desde la terminal](../02-az-cli/)
> Teoría: [apuntes/03-app-service.md](../../apuntes/03-app-service.md)

## Objetivo

Desplegar la API .NET de `app/DockerLab/` en Azure App Service, en el nivel gratuito, y que
responda en una URL pública con HTTPS.

El lab se hizo en dos pasadas, y la comparación entre las dos **es** el lab:

| | Parte 1 (06/10) | Parte 2 (09/10) |
|---|---|---|
| Cómo | `az webapp up`, un comando | Las cuatro piezas por separado |
| Quién compila | Azure, con Oryx | Mi máquina, con `dotnet publish` |
| Quién elige los nombres | Azure | Yo |
| Resultado | Lo mismo, pero sin saber qué pasó | Lo mismo, y un script que lo repite |

Se despliega **código**, no una imagen de contenedor. Desplegar imágenes (registro de contenedores
y Container Apps) es un tema posterior.

## Antes de empezar

- Azure CLI con sesión iniciada (ver [lab 02](../02-az-cli/)).
- El SDK de .NET en local.
- Un nombre libre: el de la web app es **único en todo Azure** y se convierte en
  `https://<nombre>.azurewebsites.net`.

Y una comprobación previa que viene del tropiezo del [lab 01](../01-primer-grupo-de-recursos/),
donde West Europe rechazó recursos nuevos:

```bash
az appservice list-locations --sku F1 --linux-workers-enabled --output table
```

`France Central` sale en la lista, así que se usa esa, la misma que en los labs 01 y 02.

---

## Parte 1 — El camino corto

```bash
cd app/DockerLab
az webapp up --name <nombre-único> --sku F1 --os-type linux --location francecentral
```

### Lo primero que dijo el comando

```
This command has been deprecated and will be removed in a future release.
Use 'webapp create and webapp deploy' instead.
```

### Resultado real

```
No --runtime specified. Using dotnetcore version: 8.0.
No --plan specified. Auto-generated plan: 'garciarodriguezmanuel61_asp_5343'.
Creating Resource group 'garciarodriguezmanuel61_rg_6198' ...
Resource provider 'Microsoft.Web' used by this operation is not registered. We are registering for you.
Status: Building the app... Time: 1(s)
Status: Build successful. Time: 50(s)
Status: Starting the site... Time: 66(s)
Status: Site started successfully. Time: 113(s)
```

```json
{
  "URL": "http://dockerlab-manueh-21267.azurewebsites.net",
  "appserviceplan": "garciarodriguezmanuel61_asp_5343",
  "location": "francecentral",
  "resourcegroup": "garciarodriguezmanuel61_rg_6198",
  "runtime_version": "dotnetcore|8.0",
  "sku": "FREE"
}
```

La URL respondió por **https**, aunque Azure la anunciara por http:

```
$ curl https://dockerlab-manueh-21267.azurewebsites.net/weatherforecast
[{"date":"2026-10-07","temperatureC":-8,"summary":"Cool","temperatureF":18}, ...]
```

### Dos recursos, no uno

```
$ az resource list --resource-group garciarodriguezmanuel61_rg_6198 --output table
Name                              Type
--------------------------------  -------------------------
garciarodriguezmanuel61_asp_5343  Microsoft.Web/serverFarms   ← el plan: la máquina, lo que factura
dockerlab-manueh-21267            Microsoft.Web/sites         ← la aplicación
```

### Lo que enseñaron los logs

**1. Esto es un contenedor.**

```
Pulling image: appsvc/dotnetcore:8.0_20260616.2.tuxprod
Creating container with image: ... from registry: 10.1.0.5:13209
Running the command: dotnet "DockerLab.dll"
Container start method finished after 39606 ms.
Site startup probe succeeded after 14.1458042 seconds.
Site is running with patch version DOTNETCORE-8.0.28
```

Y la frase que cierra el círculo con el [lab 05 de Docker](../../../docker/labs/05-volumenes/):

```
Note: Any data outside '/home' is not persisted
```

**2. La app no habla HTTPS.**

```
Now listening on: http://[::]:8080
warn: Microsoft.AspNetCore.HttpsPolicy.HttpsRedirectionMiddleware[3]
      Failed to determine the https port for redirect.
```

Azure termina el TLS en el borde. Hacia dentro va HTTP plano en el 8080, y por eso
`app.UseHttpsRedirection()` no encuentra puerto al que redirigir.

**3. La compilación fue en Azure.**

```
SCM_DO_BUILD_DURING_DEPLOYMENT: true
Running oryx create-script ...
Found build manifest file at '/home/site/wwwroot/oryx-manifest.toml'
```

`az webapp up` zipeó **toda** la carpeta —`bin/` y `obj/` incluidos— y Oryx compiló en el servidor.

---

## Parte 2 — Las cuatro piezas

Lo mismo, escrito. Los nombres ahora **dicen de qué lab son**.

```bash
GRUPO="rg-lab03-appservice"
REGION="francecentral"
PLAN="plan-lab03"
APP="dockerlab-manueh-$RANDOM"
RUNTIME="DOTNETCORE|8.0"      # la barra es un pipe: SIEMPRE entre comillas

# 1. el grupo
az group create --name "$GRUPO" --location "$REGION"

# 2. el plan: la máquina. Lo que factura.
az appservice plan create --name "$PLAN" --resource-group "$GRUPO" --sku F1 --is-linux

# 3. la web app: lo que corre dentro del plan
az webapp create --name "$APP" --resource-group "$GRUPO" --plan "$PLAN" --runtime "$RUNTIME"

# 4. el código: compilado AQUÍ, subido ya hecho
dotnet publish -c Release -o ./publicar
(cd publicar && zip -r ../app.zip .)
az webapp deploy --name "$APP" --resource-group "$GRUPO" --src-path app.zip --type zip
```

### La prueba de que Oryx no compiló nada

El martes, en los logs de arranque:

```
Found build manifest file at '/home/site/wwwroot/oryx-manifest.toml'
```

Hoy, los mismos logs:

```
Could not find build manifest file at '/home/site/wwwroot/oryx-manifest.toml'
```

No hay manifiesto porque **no hubo compilación en el servidor**. Y el propio `az webapp deploy` lo
avisa antes de empezar:

```
Note: 'az webapp deploy' does not run build automation (dependency installation, compilation, etc.)
by default for Linux web apps. If your package is not pre-built, set the app setting
SCM_DO_BUILD_DURING_DEPLOYMENT=true to enable builds during deployment.
```

### Las cifras de las dos pasadas

| | Parte 1 (`webapp up`) | Parte 2 (4 piezas) |
|---|---|---|
| Despliegue completo | **113 s** | **17 s** |
| Arranque del contenedor | 39.606 ms | **966 ms** |
| Sonda de warm-up | 14,1 s | 9,3 s |
| Compilación local | — | 1,9 s (restore 0,2 s + build 1,4 s) |
| Manifiesto de Oryx | Encontrado | **No encontrado** |
| Contenido del zip | la carpeta entera, con `bin/` y `obj/` | **13 ficheros, 853 K** |
| Nombre del grupo | `garciarodriguezmanuel61_rg_6198` | `rg-lab03-appservice` |

El zip de la parte 2 lleva solo lo que hace falta para ejecutar:

```
DockerLab · DockerLab.dll · DockerLab.deps.json · DockerLab.runtimeconfig.json
appsettings.json · web.config · Microsoft.OpenApi.dll · Microsoft.AspNetCore.OpenApi.dll
Swashbuckle.AspNetCore.{Swagger,SwaggerGen,SwaggerUI}.dll · DockerLab.pdb
DockerLab.staticwebassets.endpoints.json
```

Ni un `.cs`, ni `obj/`, ni `bin/`.

### El plan, antes y después

```
$ az appservice plan list --output table     # recién creado
Name        NumberOfSites  Reserved  Sku
plan-lab03  0              True      Free       ← vacío: el plan existe sin apps dentro

$ az appservice plan list --output table     # tras crear la web app
Name        NumberOfSites  Reserved  Sku
plan-lab03  1              True      Free
```

`Reserved: True` es como Azure marca que el plan es de Linux.

---

## El arreglo del HTTPS, y por qué no arregla el aviso

`az webapp create` deja la app con `HttpsOnly: False`. Se activa así:

```bash
az webapp update --name "$APP" --resource-group "$GRUPO" --https-only true
```

**Funciona**, y se comprueba con una petición en claro:

```
$ curl -I http://dockerlab-manueh-26864.azurewebsites.net/weatherforecast
HTTP/1.1 301 Moved Permanently
Location: https://dockerlab-manueh-26864.azurewebsites.net/weatherforecast
```

Ese 301 lo da **Azure en el borde**, no la aplicación.

**Pero el aviso del middleware sigue apareciendo** en el arranque siguiente:

```
2026-10-09T15:47:19  warn: HttpsRedirectionMiddleware[3]
                     Failed to determine the https port for redirect.
```

Y es lógico: `--https-only` es una opción **de Azure**, no del contenedor. Dentro, la app sigue
escuchando `http://[::]:8080` y sigue sin encontrar puerto HTTPS al que redirigir.

> **La conclusión:** con la redirección hecha en el borde, `app.UseHttpsRedirection()` es **código
> muerto** en este modelo de despliegue. Arreglar el síntoma de verdad es quitarlo del
> `Program.cs`, no silenciarlo — y eso ya es tocar la aplicación.

Otro detalle que salió solo: activar `--https-only` provocó un **`New Cold Start Attempt`**.
**Cambiar configuración en App Service reinicia el contenedor.**

---

## Los scripts

`desplegar.sh` hace los cuatro pasos más el `--https-only`, y `borrar-lab.sh` borra el grupo y
comprueba que no quedan planes huérfanos.

Tres decisiones de diseño:

- **`borrar-lab.sh` no lleva `--no-wait`.** Es más lento, pero sin eso el `desplegar.sh` siguiente
  chocaría con un grupo a medio borrar. La comodidad de salir rápido rompe la reproducibilidad.
- **El nombre de la app se genera con `$RANDOM` en cada ejecución**, porque es único global.
  El grupo y el plan van fijos, porque solo son únicos dentro de la suscripción. Mismo criterio que
  el storage del [lab 02](../02-az-cli/).
- **El script localiza `app/DockerLab` a partir de su propia ruta**, no del directorio desde el que
  se lance.

---

## Qué queda pendiente a propósito

- **El reintento ante throttling** en `desplegar.sh`. Está documentado arriba, sin implementar.
- **Quitar `app.UseHttpsRedirection()`** del `Program.cs`: es código muerto en este modelo de
  despliegue, pero tocarlo es cambiar la aplicación, no el despliegue.
- **Migrar a .NET 10.** `az webapp list-runtimes --os linux` marca .NET 8.0 (LTS) como `Near`, con
  fin de soporte el **10/11/2026**. La única LTS con recorrido es .NET 10.0, hasta el 14/11/2028.
- **Variables de entorno y cadenas de conexión** (`az webapp config appsettings set`): esta app no
  habla con ninguna base de datos.
- **Identidad gestionada** en lugar de secretos en configuración: el paso natural cuando la app
  tenga algo a lo que conectarse.
- **Slots de despliegue** (staging a producción sin corte): no existen en el nivel gratuito.
- **Desplegar la imagen Docker** en vez del código: necesita un registro de contenedores.

---

## La limpieza

```bash
./borrar-lab.sh
```

```
$ az group list --output table
(vacío)

$ az appservice plan list --output table
(vacío)
```

La segunda comprobación es la que importa: **lo que factura es el plan, no la app**. Borrar la web
app y dejar el plan es seguir pagando.

`az webapp up` deja además un `.azure/config` en la carpeta del proyecto con los nombres que eligió.
No lleva secretos, pero es estado local de despliegue que apunta a recursos ya borrados: va al
`.gitignore`, junto a `publicar/` y `app.zip`.