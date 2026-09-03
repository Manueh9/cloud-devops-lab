# Lab 02 · Multi-stage build: adelgazar la imagen del lab 01

## Objetivo

Coger el Dockerfile de una sola etapa del [lab 01](../01-primera-imagen-dotnet/) y partirlo
en dos etapas, de forma que la imagen final contenga solo el runtime de .NET y la
aplicación publicada, en vez del SDK completo. La API tiene que seguir respondiendo
exactamente igual.

Teoría detrás de este lab: [apuntes/04 · Multi-stage builds](../../apuntes/04-multi-stage.md).

---

## Punto de partida

La imagen del lab 01 (`dockerlab:v1`) partía de `mcr.microsoft.com/dotnet/sdk:8.0` y se
quedaba ahí, así que arrastraba el SDK entero a producción.

> **Nota sobre cómo medir.** En versiones recientes de Docker, `docker images` muestra dos
> columnas, `DISK USAGE` y `CONTENT SIZE`, en lugar de la clásica `SIZE`. Miden cosas
> distintas. En este lab se compara siempre **DISK USAGE** contra **DISK USAGE**.

---

## Pasos reproducibles
 
Todos los comandos se ejecutan **desde la raíz del repo**.
 
```bash
# 1. (Si aún no la tienes) reconstruir la imagen del lab 01, para tener con qué comparar
docker build -f docker/labs/01-primera-imagen-dotnet/Dockerfile -t dockerlab:v1 app/DockerLab
 
# 2. Construir la imagen de este lab, con la receta de dos etapas
docker build -f docker/labs/02-multi-stage/Dockerfile -t dockerlab:v2 app/DockerLab
 
# 3. Levantarla en el puerto 8081 del host, para no chocar
#    con el contenedor del lab 01 si sigue vivo
docker run -d --name api2 -p 8081:8080 dockerlab:v2
 
# 4. Comprobar que responde igual que la v1
curl http://localhost:8081/weatherforecast
 
# 5. Comparar tamaños
docker images
```
 
> **Por qué `-f` y no `cd` a la carpeta de la app.** `docker build` recibe dos cosas
> distintas: la **receta** (`-f ruta/al/Dockerfile`) y el **contexto**, que es el último
> argumento y define qué archivos puede copiar el `COPY` (aquí, `app/DockerLab`). Al
> separarlos, cada lab guarda su propio Dockerfile en su carpeta y ninguno sobrescribe al
> anterior: el del lab 01 sigue intacto y puedes reconstruirlo cuando quieras.
 

---

## Resultado

### Salida de `docker images`

<section>

<summary>Solución</summary>
```console
$ docker images dockerlab:v2
IMAGE          ID             DISK USAGE   CONTENT SIZE   EXTRA
dockerlab:v2   3ebab80a7c89        324MB         91.2MB    U   
```



### Comparativa

| Imagen | Imagen base | DISK USAGE | Reducción |
|---|---|---|---|
| `dockerlab:v1` (una etapa) | `dotnet/sdk:8.0` | 1,28 GB | — |
| `dockerlab:v2` (multi-stage) | `dotnet/aspnet:8.0` | 324MB | 74,7 % |

### Salida del `curl`

```console
$ curl http://localhost:8081/weatherforecast

[{"date":"2026-09-04","temperatureC":49,"summary":"Scorching","temperatureF":120},
 {"date":"2026-09-05","temperatureC":38,"summary":"Warm","temperatureF":100},
 {"date":"2026-09-06","temperatureC":18,"summary":"Mild","temperatureF":64},
 {"date":"2026-09-07","temperatureC":-10,"summary":"Cool","temperatureF":15},
 {"date":"2026-09-08","temperatureC":41,"summary":"Scorching","temperatureF":105}]
```

</section>

---

## Errores con los que me topé

> Rellenar con lo que haya pasado de verdad. Los dos habituales, por si caen:

- **`Could not execute because the specified file was not found: DockerLab.dll`** — la ruta
  del `ENTRYPOINT` sigue siendo la del lab 01 (`out/DockerLab.dll`). Al copiar el contenido
  de `/app/out` a `/app`, la DLL queda en `/app/DockerLab.dll`. Para inspeccionar la imagen
  por dentro: `docker run --rm -it --entrypoint sh dockerlab:v2` y luego `ls`.
- **`port is already allocated`** — el contenedor del lab 01 sigue ocupando el 8080.
  O se usa el 8081 como aquí, o `docker stop api && docker rm api`.
- **La imagen construye pero la API no arranca** — se ha usado `dotnet/runtime` en vez de
  `dotnet/aspnet`. Una Web API necesita ASP.NET Core, que solo viene en la segunda.

---

## Qué queda pendiente a propósito

Este lab hace **una sola cosa**: separar compilación de ejecución. Deliberadamente **no**
incluye:

- `.dockerignore`, así que las carpetas `bin/` y `obj/` locales todavía se copian a la etapa
  de build. No acaban en la imagen final, pero ensucian y ralentizan el build. → lab 03.
- Cacheo de la restauración de NuGet (copiar el `.csproj` y hacer `dotnet restore` antes que
  el resto del código). Es una optimización de caché de capas y merece su propio lab.
- Usuario no-root: el contenedor sigue ejecutándose como root. → lab 03.
- Imágenes base más pequeñas (`alpine`, `chiseled`), que reducen más a cambio de
  complicaciones.

---

⬅️ Anterior: [Lab 01 · Primera imagen con una API .NET](../01-primera-imagen-dotnet/)
➡️ Siguiente: (pendiente) Lab 03 · `.dockerignore`, variables de entorno y usuario no-root
🏠 [Índice de Docker](../../README.md) · [Portada del repo](../../../README.md)