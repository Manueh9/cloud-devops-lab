# 03 · Chuleta de comandos

> Los comandos que uso de verdad, con qué hace cada uno y las trampas de cada uno.
> No es la lista completa de Docker: es la lista corta que resuelve el 90% del día.

---

## Comprobar que Docker vive

```bash
docker --version          # versión del cliente
docker info               # estado del daemon (si esto falla, Docker no está corriendo)
docker run hello-world    # test de humo: descarga una imagen mínima y la ejecuta
```

Si `docker info` da un error de permisos en Linux, tu usuario no está en el grupo `docker`.
Se arregla con `sudo usermod -aG docker $USER` y **volviendo a iniciar sesión** (esto
último se olvida siempre).

---

## Imágenes

```bash
docker images                     # listar imágenes locales
docker pull nginx                 # descargar una imagen del registro
docker build -t nombre:tag .      # construir desde el Dockerfile de esta carpeta
docker rmi nombre:tag             # borrar una imagen
docker history nombre:tag         # ver las capas y cuánto ocupa cada una
```

Sobre `docker build -t nombre:tag .`:

- `-t` pone nombre y tag. Sin él, la imagen sale sin nombre (`<none>`) y da pena.
- **El `.` final no es decorativo**: es el *contexto de build*, la carpeta que se le manda
  al daemon. Todo lo que haya ahí dentro viaja (por eso importa el `.dockerignore`).

---

## Contenedores: arrancar

```bash
docker run imagen                          # arrancar en primer plano
docker run -d imagen                       # -d = detached, en segundo plano
docker run -p 8080:8080 imagen             # mapear puerto host:contenedor
docker run --name mi-api imagen            # ponerle nombre (si no, Docker inventa uno)
docker run --rm imagen                     # borrarlo automáticamente al terminar
docker run -it imagen bash                 # entrar con una shell interactiva
```

Combinación del día a día:

```bash
docker run -d --name mi-api -p 8080:8080 dockerlab:v1
```

---

## Contenedores: mirar y gestionar

```bash
docker ps                  # los que están corriendo
docker ps -a               # todos, incluidos los parados
docker logs <id|nombre>    # ver su salida
docker logs -f <id>        # seguir los logs en vivo (-f = follow)
docker exec -it <id> bash  # abrir una shell DENTRO de un contenedor que ya corre
docker stop <id>           # pararlo (le pide que termine, con educación)
docker start <id>          # volver a arrancar uno parado
docker rm <id>             # borrarlo
docker inspect <id>        # toda su configuración en JSON
```

Detalles útiles:

- **No hace falta el ID entero**: con los primeros caracteres basta (`docker logs a3f`).
- `docker stop` da unos segundos de margen antes de matar el proceso. `docker kill` no.
- No puedes borrar un contenedor corriendo: primero `stop`, luego `rm`.
- Si `docker exec ... bash` falla con "executable file not found", esa imagen no trae bash.
  Prueba `sh`.

---

## Limpiar cuando se acumula basura

```bash
docker ps -aq | xargs docker rm      # borrar todos los contenedores parados
docker image prune                   # borrar imágenes huérfanas (<none>)
docker system df                     # cuánto espacio está ocupando Docker
docker system prune                  # limpieza general (pregunta antes)
```

⚠️ `docker system prune -a` borra **todas** las imágenes que no estén en uso. Rápido y
efectivo, pero luego toca volver a descargarlo todo.

---

## El ciclo completo, de principio a fin

```bash
docker build -t dockerlab:v1 .                        # 1. construir
docker run -d --name api -p 8080:8080 dockerlab:v1    # 2. arrancar
docker ps                                             # 3. comprobar que vive
curl http://localhost:8080/weatherforecast            # 4. probar
docker logs api                                       # 5. ver qué ha pasado
docker stop api && docker rm api                      # 6. recoger
```

---

## Otros comandos

```bash
docker build -f docker/labs/02-multi-stage/Dockerfile -t dockerlab:v2 app/DockerLab

```


---
## Para leer más

- [Docker CLI reference](https://docs.docker.com/reference/cli/docker/) (doc oficial)

⬅️ Anterior: [02 · Anatomía de un Dockerfile](02-anatomia-dockerfile.md)
➡️ Siguiente: [04 · Multi-stage builds](04-multi-stage.md)
