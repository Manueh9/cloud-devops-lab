# 03 · App Service: dónde vive una aplicación web en Azure

> Anterior: [02 · La terminal: Azure CLI](02-azure-cli.md) · Siguiente: *(pendiente)*
> Lab que lo acompaña: [labs/03-app-service](../labs/03-app-service/)

## 1. Qué es PaaS

Publicar una aplicación web exige un sistema operativo parcheado, un runtime, un servidor web y un
certificado. App Service es **PaaS**: todo eso lo pone y lo mantiene Azure. Lo único que se aporta
es el código.

| Modelo | Mantiene el sistema | Mantiene el runtime | Control | Trabajo |
|---|---|---|---|---|
| Máquina virtual (IaaS) | Tú | Tú | Máximo | Máximo |
| Contenedor | Tú (el anfitrión) | Tú (en la imagen) | Alto | Medio |
| App Service (PaaS) | Azure | Azure | Menor | Mínimo |

> **Analogía.** IaaS es alquilar un local vacío y montarlo. PaaS es alquilar uno ya montado: se
> entra con la mercancía. A cambio, no se puede tirar un tabique.

## 2. PaaS es un contenedor con la fontanería escondida

Esto no es teoría: está en los logs del lab. Al desplegar, Azure se baja una imagen de un registro
interno y arranca un contenedor con ella:

```
Pulling image: appsvc/dotnetcore:8.0_20260616.2.tuxprod
Creating container with image: appsvc/dotnetcore:8.0_... from registry: 10.1.0.5:13209
Running the command: dotnet "DockerLab.dll"
Container is running.
```

Es decir, **App Service no sustituye a los contenedores: los oculta**. Tú traes el código, Azure
pone la imagen base y el proceso. Y se aplica la misma regla de efimeridad que en Docker, dicha por
el propio arranque:

```
Note: Any data outside '/home' is not persisted
```

Mismo concepto que un volumen de Docker, otra capa. Lo que no está en `/home` desaparece al
reiniciar el contenedor.

## 3. El plan y la app: la distinción que hay que tener clara

> *"An app service always runs in an App Service plan."*

El **plan** es la máquina: región, tamaño y tarifa, y **es lo que factura**. La **web app** es la
aplicación que corre dentro. Varias apps pueden compartir un plan: comparten su CPU, su memoria y
su disco, y escalan juntas.

```
APP SERVICE PLAN  (región, tamaño, precio)   ← lo que se paga
 ├── web app 1
 ├── web app 2
 └── web app 3                                ← se reparten los mismos recursos
```

> **Analogía (C#).** El plan es el proceso; las web apps son los hilos que corren dentro. Añadir un
> hilo no da más CPU: reparte la que ya hay.

Consecuencia práctica: **borrar la web app no deja de facturar; hay que borrar el plan.** De ahí
que la comprobación final de cualquier lab de App Service sea `az appservice plan list`, no solo
`az group list`.

## 4. El nivel gratuito F1

| Límite del plan F1 | Valor |
|---|---|
| Apps por plan | 10 |
| Almacenamiento | 1 GB |
| Tiempo de CPU al día | 60 minutos |
| Memoria por hora y plan | 1.024 MB |
| Escalado horizontal | 1 instancia compartida (no escala) |
| Dominios propios | 0 (solo `*.azurewebsites.net`) |

El nombre de la web app es **único en todo Azure**, porque se convierte en la URL.

## 5. El HTTPS es gratis porque tu app no lo ve

El certificado comodín de `*.azurewebsites.net` hace que `https://` funcione desde el primer
momento, sin configurar nada. El motivo está en los logs:

```
Now listening on: http://[::]:8080
```

La aplicación escucha **HTTP plano** en el 8080. **Azure termina el TLS en el borde** y hacia dentro
habla en claro. Por eso hay candado sin haber tocado un certificado.

Eso tiene una consecuencia que da un aviso real:

```
warn: Microsoft.AspNetCore.HttpsPolicy.HttpsRedirectionMiddleware[3]
      Failed to determine the https port for redirect.
```

`app.UseHttpsRedirection()` busca un puerto HTTPS local al que redirigir y no hay ninguno. **La
solución no es tocar el middleware: es que redirija Azure**, en el borde, antes de llegar al
contenedor:

```bash
az webapp update --name <app> --resource-group <grupo> --https-only true
```

## 6. Dónde se compila el código

```
SCM_DO_BUILD_DURING_DEPLOYMENT: true
Running oryx create-script ...
Found build manifest file at '/home/site/wwwroot/oryx-manifest.toml'
```

Con `az webapp up`, **la compilación ocurre en Azure**: se sube el código fuente y un sistema
llamado **Oryx** lo compila allí. Por eso el zip incluye `bin/` y `obj/`, que no pintan nada.

La alternativa —`dotnet publish` en local y subir solo el resultado— es más rápida, más predecible y
es lo que hace un pipeline de CI/CD. Es el lab de la parte 2.

## 7. `az webapp up` está deprecado

Literal, en la salida del comando:

> *"This command has been deprecated and will be removed in a future release. Use 'webapp create
> and webapp deploy' instead."*

Lo que agrupa, y que hay que saber escribir por separado:

| Lo que ejecuta por dentro | Qué crea |
|---|---|
| `az group create` | El grupo de recursos |
| `az appservice plan create` | El plan (la máquina) |
| `az webapp create` | La aplicación |
| `dotnet publish` + zip + `az webapp deploy` | La subida del código |

Además elige los nombres por su cuenta, y los elige mal: generó el grupo
`garciarodriguezmanuel61_rg_6198` y el plan `garciarodriguezmanuel61_asp_5343`. Ninguno dice qué lab
es, lo que choca con la regla de esta carpeta de un grupo por lab con nombre reconocible.

## 8. Proveedores de recursos

```
Resource provider 'Microsoft.Web' used by this operation is not registered. We are registering for you.
```

Una suscripción no puede crear un tipo de recurso hasta que su **proveedor** está registrado. Azure
lo hizo solo en este caso, pero no siempre: a veces hay que registrarlo a mano.

```bash
az provider list --query "[?registrationState=='Registered'].namespace" -o table
az provider register --namespace Microsoft.Web
```

## 9. Mis cifras de este lab

| Dato | Valor |
|---|---|
| URL | `https://dockerlab-manueh-21267.azurewebsites.net` |
| Región | `francecentral` |
| SKU | `FREE` (F1), Linux |
| Runtime detectado | `dotnetcore|8.0`, parche `DOTNETCORE-8.0.28` |
| Imagen base que usó Azure | `appsvc/dotnetcore:8.0_20260616.2.tuxprod` |
| Despliegue completo | 113 s (build 50 s, arranque del sitio el resto) |
| Arranque del contenedor | 39,6 s |
| Sonda de warm-up | 14,1 s |
| Instancia | `10-30-0-143` |