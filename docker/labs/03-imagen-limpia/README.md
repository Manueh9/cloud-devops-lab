# Lab 03 · Imagen limpia: `.dockerignore`, variables de entorno y usuario no-root


## Objetivo

Coger la imagen multi-etapa del lab 02 y dejarla en condiciones de producción en tres
aspectos: que no arrastre ficheros innecesarios al build, que se pueda configurar desde
fuera sin reconstruirla, y que no se ejecute como root.

Teoría detrás de este lab: [apuntes/05-imagen-limpia.md](../../apuntes/05-imagen-limpia.md)


## Requisitos

- Haber hecho el [lab 02](../02-multi-stage/).
- Docker y el SDK de .NET instalados.
- Ejecutar todos los comandos **desde la raíz del repositorio**.

## Pasos reproducibles

### 1. Medir el contexto antes del `.dockerignore`

```bash
du -sh app/DockerLab
ls -la app/DockerLab
```

Si no existen `bin/` ni `obj/`, créalas compilando (el `.gitignore` del repositorio las
mantiene fuera del control de versiones, así que un clon recién bajado no las tiene):

```bash
( cd app/DockerLab && dotnet build )
```

Construye con la receta del lab anterior y anota la línea `transferring context`:

```bash
docker build -f docker/labs/02-multi-stage/Dockerfile -t dockerlab:v2-recontexto app/DockerLab
```

### 2. Añadir el `.dockerignore` en la raíz del contexto

El fichero va en `app/DockerLab/.dockerignore`, **no** junto al Dockerfile. Docker lo busca
en la raíz del contexto de build.

### 3. Construir la v3 y volver a medir

```bash
docker build -f docker/labs/03-imagen-limpia/Dockerfile -t dockerlab:v3 app/DockerLab
```

### 4. Comprobar el usuario y la aplicación

```bash
docker run -d --name api3 -p 8082:8080 dockerlab:v3
docker exec api3 whoami
docker exec api3 id
curl http://localhost:8082/weatherforecast
```

### 5. Comprobar que la configuración se pisa desde fuera

```bash
docker logs api3 | head -20
docker rm -f api3
docker run -d --name api3 -p 8082:8080 -e ASPNETCORE_ENVIRONMENT=Development dockerlab:v3
docker logs api3 | head -20
```

## Resultado real

Contexto de build transferido:

| | `transferring context` |
|---|---|
| Sin `.dockerignore` | ~8 MB  ← orientativo, depende de tus bin/ y obj/ |
| Con `.dockerignore` | ~440 B |
| Reducción | ~99 % |

Usuario dentro del contenedor:

```
$ docker exec api3 whoami
app

$ docker exec api3 id
uid=1654(app) gid=1654(app) groups=1654(app)
```

Respuesta de la API:

```
$ curl http://localhost:8082/weatherforecast
[{"date":"2026-09-16","temperatureC":-10,"summary":"Freezing","temperatureF":15},{"date":"2026-09-17","temperatureC":-19,"summary":"Mild","temperatureF":-2},{"date":"2026-09-18","temperatureC":-5,"summary":"Warm","temperatureF":24},{"date":"2026-09-19","temperatureC":-17,"summary":"Warm","temperatureF":2},{"date":"2026-09-20","temperatureC":36,"summary":"Mild","temperatureF":96}]vbox
```

Logs con `ASPNETCORE_ENVIRONMENT` por defecto y con el valor pisado desde fuera:

```
info: Microsoft.Hosting.Lifetime[0]
      Hosting environment: Production

info: Microsoft.Hosting.Lifetime[0]
      Hosting environment: Development
```

## Qué queda pendiente a propósito

- **La caché de capas.** Esta imagen se sigue reconstruyendo entera cada vez que cambia una
  línea de código. Eso se ataca en el lab 04.
- **Los secretos.** Aquí solo hemos movido configuración no sensible. Una contraseña no
  puede ir en un `ENV`: queda escrita en la imagen. Se resolverá con un gestor de secretos
  mucho más adelante.
- **El sistema de ficheros sigue siendo de escritura.** Endurecerlo (`--read-only`,
  capacidades) es tema de seguridad de contenedores, no de este lab.

## Limpieza

```bash
docker rm -f api3
docker rmi dockerlab:v2-recontexto
```

---

⬅️ Anterior: [lab 02 · Multi-stage build](../02-multi-stage/)
➡️ Siguiente: *(pendiente)*
🏠 [Índice de Docker](../../README.md) · [Portada del repo](../../../README.md)