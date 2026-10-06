# Lab 03 · La API .NET en App Service — parte 1: el camino corto

> Anterior: [lab 02 · Los mismos recursos, desde la terminal](../02-az-cli/)
> Teoría: [apuntes/03-app-service.md](../../apuntes/03-app-service.md)

**Este lab tiene dos partes.** Esta es la primera: desplegar con el comando de conveniencia
`az webapp up` y mirar qué hace por dentro. La parte 2 repite el despliegue escribiendo por separado
las cuatro piezas que ese comando agrupa.

## Objetivo

Que la API .NET de `app/DockerLab/` responda en una URL pública con HTTPS, desplegada desde la
terminal, y borrarlo todo al terminar sin dejar nada facturando.

Se despliega **código**, no una imagen de contenedor. Desplegar imágenes (registro de contenedores y
Container Apps) es un tema posterior.

## Antes de empezar

- Azure CLI con sesión iniciada (ver [lab 02](../02-az-cli/)).
- El SDK de .NET en local.
- Un nombre libre: el de la web app es **único en todo Azure** y se convierte en
  `https://<nombre>.azurewebsites.net`.

## Comprobación previa: ¿está el F1 en mi región?

El lab 01 se topó con una región saturada, así que conviene mirar antes dónde está disponible el
nivel gratuito para Linux:

```bash
az appservice list-locations --sku F1 --linux-workers-enabled --output table
```

`France Central` sale en la lista, así que se usa esa, la misma que en los labs 01 y 02.

## El despliegue

```bash
cd app/DockerLab

az webapp up \
    --name dockerlab-manueh-$RANDOM \
    --sku F1 \
    --os-type linux \
    --location francecentral
```

## Resultado real

```
$ az webapp up --name dockerlab-manueh-$RANDOM --sku F1 --os-type linux --location francecentral
This command has been deprecated and will be removed in a future release.
Use 'webapp create and webapp deploy' instead.
No --runtime specified. Using dotnetcore version: 8.0.
No --plan specified. Auto-generated plan: 'garciarodriguezmanuel61_asp_5343'.
Creating Resource group 'garciarodriguezmanuel61_rg_6198' ...
Resource provider 'Microsoft.Web' used by this operation is not registered. We are registering for you.
Status: Building the app... Time: 1(s)
Status: Build successful. Time: 50(s)
Status: Starting the site... Time: 66(s)
Status: Site started successfully. Time: 113(s)
You can launch the app at http://dockerlab-manueh-21267.azurewebsites.net
```

```json
{
  "URL": "http://dockerlab-manueh-21267.azurewebsites.net",
  "appserviceplan": "garciarodriguezmanuel61_asp_5343",
  "location": "francecentral",
  "name": "dockerlab-manueh-21267",
  "os": "Linux",
  "resourcegroup": "garciarodriguezmanuel61_rg_6198",
  "runtime_version": "dotnetcore|8.0",
  "sku": "FREE"
}
```

La URL, por **https**, aunque Azure la anunciara por http:

```
$ curl https://dockerlab-manueh-21267.azurewebsites.net/weatherforecast
[{"date":"2026-10-07","temperatureC":-8,"summary":"Cool","temperatureF":18},
 {"date":"2026-10-08","temperatureC":20,"summary":"Hot","temperatureF":67},
 {"date":"2026-10-09","temperatureC":49,"summary":"Hot","temperatureF":120},
 {"date":"2026-10-10","temperatureC":5,"summary":"Scorching","temperatureF":40},
 {"date":"2026-10-11","temperatureC":0,"summary":"Sweltering","temperatureF":32}]
```

## Qué creó, exactamente

```
$ az resource list --resource-group garciarodriguezmanuel61_rg_6198 --output table
Name                              Location       Type                       Status
--------------------------------  -------------  -------------------------  ---------
garciarodriguezmanuel61_asp_5343  francecentral  Microsoft.Web/serverFarms  Succeeded
dockerlab-manueh-21267            francecentral  Microsoft.Web/sites        Succeeded
```

**Dos recursos, no uno.** `serverFarms` es el plan —la máquina, lo que factura— y `sites` es la web
app. Del listado del plan: SKU `FREE`, `Reserved: True` (que es como Azure marca que es Linux),
1 sitio, 1 worker, sin escalado.

## Lo que enseñaron los logs

```bash
az webapp log tail --name dockerlab-manueh-21267 --resource-group garciarodriguezmanuel61_rg_6198
```

**1. Es un contenedor.**

```
Pulling image: appsvc/dotnetcore:8.0_20260616.2.tuxprod
Creating container with image: appsvc/dotnetcore:8.0_... from registry: 10.1.0.5:13209
Running the command: dotnet "DockerLab.dll"
Container start method finished after 39606 ms.
Site startup probe succeeded after 14.1458042 seconds.
Site is running with patch version DOTNETCORE-8.0.28
```

Y la frase que cierra el círculo con el lab 05 de Docker:

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
`app.UseHttpsRedirection()` no encuentra puerto al que redirigir. **Es un defecto real de
`app/DockerLab`, encontrado por accidente.** Se arregla en el borde, no en el código:

```bash
az webapp update --name <app> --resource-group <grupo> --https-only true
```

**3. La compilación fue en Azure, no en el Mac.**

```
SCM_DO_BUILD_DURING_DEPLOYMENT: true
Running oryx create-script ...
Found build manifest file at '/home/site/wwwroot/oryx-manifest.toml'
```

`az webapp up` zipeó **toda** la carpeta, `bin/` y `obj/` incluidos, y Oryx compiló en el servidor.

## Errores y cosas que salieron mal

- **`az webapp up` está deprecado**, y lo dice él mismo en su primera línea. Esto no es un fallo del
  lab: es el argumento de la parte 2.
- **Los nombres los eligió Azure, y mal:** `garciarodriguezmanuel61_rg_6198` y
  `garciarodriguezmanuel61_asp_5343`. Ninguno dice de qué lab es, lo que rompe la regla de esta
  carpeta. En la parte 2 los nombres los pongo yo.
- **El proveedor `Microsoft.Web` no estaba registrado** en la suscripción. Azure lo registró solo,
  pero conviene saber que existe `az provider register`.
- **Se subió basura compilada** al empaquetar la carpeta entera.
- **El runtime caduca pronto.** `az webapp list-runtimes --os linux` marca .NET 8.0 (LTS) como
  `Near`, fin de soporte el **10/11/2026**. La única LTS con recorrido es .NET 10.0 (hasta
  14/11/2028). Migrar `app/DockerLab` es una tarea con fecha.

## Qué queda pendiente a propósito

- **La parte 2 de este lab:** el mismo despliegue escrito en sus cuatro piezas y convertido en
  `desplegar.sh` y `borrar.sh`.
- **El redespliegue** con `az webapp up` sin argumentos, para comparar tiempos aprovechando el
  `.azure/config`. No dio tiempo.
- **Poner `--https-only true`** y comprobar que el aviso del middleware desaparece.
- **Variables de entorno y cadenas de conexión** (`az webapp config appsettings set`): esta app no
  habla con ninguna base de datos.
- **Slots de despliegue** (staging a producción sin corte): no existen en el nivel gratuito.
- **Desplegar la imagen Docker** en vez del código: necesita un registro de contenedores. Tema
  posterior.

## La limpieza

```bash
az group delete --name garciarodriguezmanuel61_rg_6198 --yes --no-wait
az group list --output table
az appservice plan list --output table
```

```
$ az group list --output table
Name                             Location       Status
-------------------------------  -------------  --------
garciarodriguezmanuel61_rg_6198  francecentral  Deleting

$ az appservice plan list --output table
(vacío)
```

Esa segunda comprobación es la que importa: **lo que factura es el plan, no la app**. Si se borra la
web app y se deja el plan, se sigue pagando.

`az webapp up` deja además un `.azure/config` en la carpeta del proyecto con los nombres que eligió.
No lleva secretos, pero es estado local de despliegue y apunta a recursos ya borrados: va al
`.gitignore`.