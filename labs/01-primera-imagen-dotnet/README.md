# Lab 01 · Mi primera imagen: una Web API de .NET dentro de un contenedor

**Objetivo:** que `curl http://localhost:8080/weatherforecast` devuelva JSON servido desde
un contenedor construido por mí. Nada más.

**Tiempo real:** una sesión de ~90 min, siendo la primera vez que tocaba Docker.

**Nivel:** cero. Si sabes lo que es una terminal, puedes seguirlo.

> ⚠️ **Este lab está a propósito sin optimizar.** La imagen resultante es enorme porque
> mete el SDK completo de .NET dentro. Eso se arregla en el lab 02 (multi-stage). Aquí el
> objetivo es entender el ciclo, no hacerlo bien del todo.

---

## Conceptos que necesitas antes de empezar

Si no tienes claro qué es una imagen, qué es un contenedor y cómo funciona el `-p`, lee
primero [apuntes/01 · Conceptos básicos](../../apuntes/01-conceptos-basicos.md). Son 10
minutos y ahorran una tarde de frustración.

---

## Paso 0 · Que Docker responda

```bash
docker --version
docker run hello-world
```

Si esto no funciona, para aquí y arréglalo. Es donde se pierde el 90% del tiempo del primer
día (Docker parado, permisos del daemon, usuario fuera del grupo `docker`).

---

## Paso 1 · Ver el ciclo con una imagen de otro

Antes de escribir nada, conviene ver el ciclo completo con algo que ya existe:

```bash
docker run -d -p 8080:80 nginx     # arrancar nginx en segundo plano
# abrir http://localhost:8080 en el navegador → sale la página de bienvenida de nginx
docker ps                          # ver el contenedor corriendo
docker logs <id>                   # ver su salida
docker stop <id>                   # pararlo
docker rm <id>                     # borrarlo
docker ps -a                       # comprobar que ya no está
```

Aquí ya has usado imagen, contenedor y mapeo de puertos sin escribir un Dockerfile.

---

## Paso 2 · La aplicación, todavía sin Docker

```bash
dotnet new webapi -n DockerLab
cd DockerLab
dotnet run
```

Comprueba que responde en local antes de meterla en un contenedor. Si falla aquí, el
problema no es Docker.

Apunta tu versión de SDK, hace falta para el tag de la imagen:

```bash
dotnet --list-sdks
```

---

## Paso 3 · El Dockerfile

Crea un fichero llamado `Dockerfile` (sin extensión) en la raíz del proyecto:

```dockerfile
# De qué partimos: una imagen que ya trae el SDK de .NET instalado
FROM mcr.microsoft.com/dotnet/sdk:8.0

# Carpeta de trabajo dentro del contenedor (se crea si no existe)
WORKDIR /app

# Copia todo lo de la carpeta actual al /app del contenedor
COPY . .

# Compila en modo Release y deja el resultado en /app/out
RUN dotnet publish -c Release -o out

# La API escuchará en el 8080 dentro del contenedor.
# El "+" significa "todas las interfaces": con "localhost" no responderías desde fuera.
ENV ASPNETCORE_URLS=http://+:8080

# Qué se ejecuta cuando arranca el contenedor
ENTRYPOINT ["dotnet", "out/DockerLab.dll"]
```

👉 Cambia `8.0` por tu versión de SDK si es otra.
👉 Explicación línea a línea en [apuntes/02 · Anatomía de un Dockerfile](../../apuntes/02-anatomia-dockerfile.md).

---

## Paso 4 · Construir y ejecutar

```bash
docker build -t dockerlab:v1 .
docker run -d --name api -p 8080:8080 dockerlab:v1
docker ps
curl http://localhost:8080/weatherforecast
```

---

## Resultado

```console
$ curl http://localhost:8080/weatherforecast
[{"date":"2026-08-27","temperatureC":-14,"summary":"Chilly","temperatureF":7},
 {"date":"2026-08-28","temperatureC":37,"summary":"Chilly","temperatureF":98},
 {"date":"2026-08-29","temperatureC":7,"summary":"Balmy","temperatureF":44},
 {"date":"2026-08-30","temperatureC":23,"summary":"Mild","temperatureF":73},
 {"date":"2026-08-31","temperatureC":15,"summary":"Mild","temperatureF":58}]
```

JSON servido desde el contenedor. Objetivo cumplido.

### Tamaño de la imagen

```console
$ docker images dockerlab
IMAGE          ID             DISK USAGE   CONTENT SIZE   EXTRA
dockerlab:v1   96271c562337       1.28GB          343MB    U
```

Ojo a las dos columnas, porque confunden:

- **DISK USAGE (1,28 GB)** → lo que ocupa de verdad en el disco, con las capas ya
  descomprimidas. Es el número que duele.
- **CONTENT SIZE (343 MB)** → lo que pesa el contenido comprimido, tal como viajaría al
  descargarse de un registro.

> Es la diferencia entre lo que pesa un `.zip` y lo que ocupa una vez descomprimido.

**1,28 GB para servir un JSON de cinco líneas.** La razón es que la imagen incluye el
**SDK completo de .NET**: unas herramientas de compilación que hacen falta para
*construir* el proyecto, pero que no pinta nada arrastrar en *ejecución*. En el lab 02 se
separan las dos cosas con un multi-stage build y se compara el antes y el después.

(La `U` de EXTRA significa "In Use": hay un contenedor usando esta imagen.)

---

## Errores con los que me topé

| Síntoma | Causa | Solución |
|---|---|---|
| `curl` no responde nada | Falta el `-p` o la app escucha en otro puerto | `-p 8080:8080` y `ASPNETCORE_URLS=http://+:8080` |
| `port is already allocated` | El puerto ya está ocupado en el host | Cambiar **el de la izquierda**: `-p 8081:8080` |
| `permission denied` al hablar con el daemon | Usuario fuera del grupo `docker` | `sudo usermod -aG docker $USER` y **volver a iniciar sesión** |
| El contenedor arranca y se para solo | El proceso principal terminó | `docker logs <id>` para ver por qué |

---

## Qué queda pendiente (a propósito)

- La imagen es enorme → **lab 02: multi-stage build**.
- `COPY . .` se lleva `bin/`, `obj/` y `.git` dentro → **lab 03: `.dockerignore`**.
- Corre como root → **lab 03: `USER`**.
- No aprovecho la caché de capas: cada cambio de código recompila todo → **lab 02**.

---

⬅️ [Volver al índice del repo](../../README.md)
