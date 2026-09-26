# Lab 07 · Docker Compose: la API .NET y su base de datos con un solo comando

> Anterior: [lab 06 · Redes](../06-redes/) · Siguiente: *(pendiente — empieza Kubernetes)*
> Teoría: [apuntes/09-compose.md](../../apuntes/09-compose.md)

## Objetivo

Levantar con **un solo comando** un sistema de dos contenedores —una Web API de .NET y una
base de datos PostgreSQL— en el que la API encuentra a la base de datos por su nombre, la base
de datos **no se publica hacia fuera**, la API espera a que esté **sana** antes de arrancar, y
los datos sobreviven a bajar y volver a levantar el sistema.

Este lab no introduce ninguna idea nueva respecto a los dos anteriores: los automatiza. Ver
primero el [lab 05](../05-volumenes/) y el [lab 06](../06-redes/) es lo que hace que este se
entienda en vez de copiarse.

## Entorno

```
Plataforma      macOS (Darwin), Apple Silicon (arm64), Docker Desktop
Motor de BD     postgres:16-alpine
```

## Ficheros de este lab

| Fichero | Para qué |
|---|---|
| `docker-compose.yml` | La declaración del sistema entero |
| `init.sql` | Crea la tabla la primera vez que se inicializa un volumen vacío |
| `Dockerfile` | Copia del lab 04 (con el `restore` adelantado) para que el lab sea autocontenido |

## Cómo se levanta

```bash
cd docker/labs/07-compose
docker compose config      # ver el fichero ya resuelto, antes de construir nada
docker compose up -d --build
docker compose ps          # la base de datos debe aparecer (healthy)
```

Comprobaciones:

```bash
curl http://localhost:8080/weatherforecast   # la API responde
docker compose exec basedatos psql -U postgres -d labdocker -c "SELECT * FROM certificados"
```

Y para bajarlo:

```bash
docker compose down        # conserva los datos
docker compose down -v     # se los lleva
```

## Decisiones tomadas, y por qué

- **La base de datos no tiene `ports`.** Dentro de la red del proyecto no hace falta publicar
  nada para que la API la alcance, y en un entorno real una base de datos no debe ser
  accesible desde fuera. El `ports` de la API sí está, porque a la API sí se le llama desde
  fuera. Se ve en `docker compose ps`: la API sale con `0.0.0.0:8080->8080/tcp` (con flecha,
  publicada) y la base de datos con `5432/tcp` (sin flecha, interna).
- **`condition: service_healthy` en lugar de `sleep`.** En los labs 05 y 06 se usaba `sleep`
  como muleta consciente. Aquí se sustituye por el mecanismo correcto.
- **Dos tipos de montaje a la vez.** Los datos del motor van en volumen nombrado; `init.sql`
  entra por bind mount de solo lectura. Cada uno para lo suyo.
- **La contraseña está escrita en el fichero a propósito.** Es un laboratorio local, todo se
  destruye al terminar y no protege nada. En un entorno real iría en un gestor de secretos, o
  como mínimo en un `.env` fuera del control de versiones. Está en la lista de pendientes.
- **`name: lab07`.** Fija el nombre del proyecto, y con él los de la red y el volumen, en vez
  de dejar que dependan del nombre de la carpeta.
- **Motor PostgreSQL, no SQL Server:** la máquina es Apple Silicon (`arm64`) y la imagen de
  SQL Server solo existe para `amd64`. Decisión de arquitectura, documentada desde el lab 05.

## Resultado real

`docker compose ps` con todo levantado:

```
NAME                IMAGE                COMMAND                  SERVICE     STATUS                    PORTS
lab07-api-1         lab07-api            "dotnet DockerLab.dll"   api         Up (running)              0.0.0.0:8080->8080/tcp, [::]:8080->8080/tcp
lab07-basedatos-1   postgres:16-alpine   "docker-entrypoint.s…"   basedatos   Up (healthy)              5432/tcp
```

La API responde (está publicada):

```
$ curl http://localhost:8080/weatherforecast
[{"date":"2026-09-27","temperatureC":-18,"summary":"Hot",...}, ... 5 elementos ...]
```

La base de datos no es accesible desde el anfitrión (no está publicada):

```
$ curl http://localhost:5432
curl: (7) Failed to connect to localhost port 5432 after 6 ms: Couldn't connect to server
```

La API ve a la base de datos por su nombre, sin ninguna IP escrita:

```
$ docker compose exec api getent hosts basedatos
172.18.0.2      basedatos
```

### La prueba de la persistencia

| Paso | Salida |
|---|---|
| Filas recién insertadas | 2 filas (Ada Lovelace, Alan Turing) |
| Después de `down` y `up` | 2 filas (siguen) |
| Después de `down -v` y `up` | `(0 rows)` — la tabla existe pero está vacía |

Consulta tras `down` (sin `-v`) y volver a levantar:

```
 id |    alumno    |         curso         |   fecha
----+--------------+-----------------------+------------
  1 | Ada Lovelace | Fundamentos de Docker | 2026-09-26
  2 | Alan Turing  | Docker Compose        | 2026-09-26
(2 rows)
```

Consulta tras `down -v` y volver a levantar:

```
 id | alumno | curso | fecha
----+--------+-------+-------
(0 rows)
```

`docker volume ls | grep lab07`: tras `down` el volumen `lab07_pgdata` seguía; tras `down -v`
desapareció y `up` lo volvió a crear vacío.

**El detalle que lo remata:** la última consulta no dio `relation "certificados" does not
exist`, dio `(0 rows)`. La tabla **existe** —`init.sql` la recreó al inicializar el volumen
nuevo y vacío— pero las filas, que se metieron a mano y no están en `init.sql`, se fueron con
el volumen borrado. Eso separa "destruir contenedores" de "destruir datos", en una sola letra.

## Errores con los que me topé

<<PEGA AQUÍ con tus palabras. El de esta sesión: ejecuté `docker compose` desde la raíz del
repositorio en vez de desde la carpeta del lab, y las rutas relativas del compose se
resolvieron tres niveles más arriba (`context` apuntaba a `/Users/.../app/DockerLab` en vez de
a `/Users/.../cloud-devops-lab/app/DockerLab`). El build falló con `path not found`.
`docker compose config` lo enseñaba antes de construir. Se arregla ejecutando desde la carpeta
donde vive el `docker-compose.yml`.>>

## Qué queda pendiente a propósito

- **Que la API consulte de verdad la base de datos** (un endpoint `/db-check` con Npgsql).
  Hoy se comprobó que la API *encuentra* a la base de datos por nombre (`getent`), pero todavía
  no la *consulta*. Es el siguiente paso, para la semana que viene.
- **El secreto sigue en texto plano** en el YAML. El siguiente paso natural es un `.env`
  ignorado por git más un `.env.example` versionado, y más adelante Azure Key Vault.
- **Un solo entorno.** No hay `docker-compose.override.yml` ni perfiles para separar
  desarrollo de producción.
- **Nada de límites de recursos** (`deploy.resources`), ni política de reinicio.
- **Compose no orquesta**: no hay réplicas, ni reprogramación si un nodo cae, ni despliegue sin
  corte. Eso es lo que viene después, y se llama Kubernetes.