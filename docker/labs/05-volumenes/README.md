# Lab 05 · Volúmenes: que los datos sobrevivan al contenedor

> Anterior: [lab 04 · Caché de capas](../04-cache-de-capas/) · Siguiente: [lab 06 · Redes](../06-redes/)
> Teoría: [apuntes/07-volumenes.md](../../apuntes/07-volumenes.md)

## Objetivo

Comprobar, con una base de datos de verdad, que el estado que escribe un contenedor
**desaparece cuando el contenedor se borra**, salvo que viva en un volumen nombrado. Y
demostrarlo con su contraprueba, que es lo que convierte una observación en una demostración.

Este lab y el [06](../06-redes/) son el escalón previo a Docker Compose: todo lo que aquí se
hace a mano es lo que Compose automatiza en un fichero YAML.

## Dos diferencias con los labs anteriores

**1. Este lab no tiene `Dockerfile` propio.** No se construye ninguna imagen: se usa la imagen
oficial de PostgreSQL tal cual, y todo el ejercicio son comandos de `docker run`,
`docker volume` y `docker exec`. Es el primer lab del repositorio del que esto es cierto, y
rompe el patrón de los cuatro anteriores a propósito.

**2. Cambia la máquina.** Los labs 01 a 04 se hicieron en una máquina virtual de VirtualBox con
Linux. Desde este, el entorno es **macOS sobre Apple Silicon con Docker Desktop**. Tiene dos
consecuencias que conviene decir antes de que confundan a nadie:

- Los tiempos de build del [lab 04](../04-cache-de-capas/) **no son comparables** con los que se
  midan a partir de aquí.
- En macOS, Docker corre el motor dentro de una VM ligera, así que "el anfitrión" que ve Docker
  no es el ordenador literalmente. Eso explica el `Mountpoint` que aparece más abajo y el número
  de memoria que reporta `docker info`.

## Entorno

```
Plataforma      macOS (Darwin), Apple Silicon (arm64)
Docker Desktop  Total Memory: 7.748GiB
Motor de BD     postgres:16-alpine
```

## Sobre la contraseña

La contraseña `Docker!Lab2026` aparece escrita en este README **a propósito**. Es un laboratorio
local, todo se destruye al terminar y no protege nada; no debe reutilizarse en ningún sitio. En
un entorno real una contraseña no va ni en el repositorio ni en una variable de entorno del
Dockerfile: va en un gestor de secretos.

> **Aviso para quien use zsh** (el shell por defecto de macOS): el `!` dentro de **comillas
> dobles** dispara la expansión de historial y rompe la contraseña. Por eso todos los comandos
> de abajo usan **comillas simples**. Si sale `zsh: event not found`, es esto.

## Pasos reproducibles

### 1. Crear el volumen

```bash
docker volume create pgdata
docker volume ls
```

### 2. Levantar la base de datos con el volumen montado

```bash
docker run -d \
  --name basedatos \
  -p 5432:5432 \
  -v pgdata:/var/lib/postgresql/data \
  -e POSTGRES_PASSWORD='Docker!Lab2026' \
  -e POSTGRES_DB=labdocker \
  postgres:16-alpine

sleep 10
docker logs basedatos | tail -20
```

El puerto se publica con `-p` **solo porque en este lab el foco es el volumen** y así se puede
conectar sin complicaciones. En el [lab 06](../06-redes/) se quita a propósito, para ver que dos
contenedores se hablan sin publicar nada hacia fuera.

### 3. Crear la tabla y meter filas

```bash
sql() {
  docker exec -e PGPASSWORD='Docker!Lab2026' basedatos \
    psql -U postgres -d labdocker -c "$1"
}

sql "SELECT version()"
sql "CREATE TABLE certificados (id SERIAL PRIMARY KEY, alumno TEXT, curso TEXT, fecha DATE)"
sql "INSERT INTO certificados (alumno, curso, fecha) VALUES
     ('Ada Lovelace','Fundamentos de Docker','2026-09-23'),
     ('Alan Turing','Volumenes en contenedores','2026-09-23')"
sql "SELECT * FROM certificados"
```

`sql()` es una función de shell, no un fichero: vive solo en la terminal donde se define. Se usa
para no repetir el comando largo cuatro veces, y porque deja cada consulta como una línea que
otro puede copiar.

### 4. Destruir el contenedor y recrearlo con el mismo volumen

```bash
docker rm -f basedatos
docker ps -a                 # el contenedor ya no existe
docker volume ls             # el volumen SIGUE existiendo

docker run -d --name basedatos -p 5432:5432 \
  -v pgdata:/var/lib/postgresql/data \
  -e POSTGRES_PASSWORD='Docker!Lab2026' -e POSTGRES_DB=labdocker \
  postgres:16-alpine

sleep 10
sql "SELECT * FROM certificados"
```

### 5. La contraprueba: lo mismo sin volumen

```bash
docker rm -f basedatos

docker run -d --name basedatos-sinvolumen -p 5433:5432 \
  -e POSTGRES_PASSWORD='Docker!Lab2026' -e POSTGRES_DB=labdocker \
  postgres:16-alpine

sleep 10

docker exec -e PGPASSWORD='Docker!Lab2026' basedatos-sinvolumen \
  psql -U postgres -d labdocker -c "SELECT * FROM certificados"
```

Se publica en el 5433 porque el 5432 podría estar ocupado, y se le da otro nombre para no
confundirlo con el contenedor anterior.

### 6. Ver la frontera del montaje

```bash
# SIN volumen: los dos numeros de dispositivo deben ser IGUALES
docker exec basedatos-sinvolumen stat -c '%d %n' / /var/lib/postgresql/data

# CON volumen: deben ser DISTINTOS
docker run --rm -v pgdata:/var/lib/postgresql/data postgres:16-alpine \
  stat -c '%d %n' / /var/lib/postgresql/data
```

### 7. Inspeccionar y limpiar

```bash
docker volume inspect pgdata

docker rm -f basedatos-sinvolumen
docker volume rm pgdata
```

## Resultado real

### Versión del motor

```
                                            version
------------------------------------------------------------------------------------------------
 PostgreSQL 16.15 on aarch64-unknown-linux-musl, compiled by gcc (Alpine 15.2.0) 15.2.0, 64-bit
(1 row)
```

### Filas recién creadas ("antes")

```
 id |    alumno    |           curso           |   fecha
----+--------------+---------------------------+------------
  1 | Ada Lovelace | Fundamentos de Docker     | 2026-09-23
  2 | Alan Turing  | Volumenes en contenedores | 2026-09-23
(2 rows)
```

### El contenedor destruido, y el volumen intacto

```
$ docker rm -f basedatos
basedatos

$ docker ps -a
CONTAINER ID   IMAGE     COMMAND   CREATED   STATUS    PORTS     NAMES

$ docker volume ls
DRIVER    VOLUME NAME
local     pgdata
```

No queda ni un contenedor. El volumen sigue ahí, porque **nunca formó parte de él**.

### Filas después de destruir el contenedor y recrearlo con el mismo volumen

```
 id |    alumno    |           curso           |   fecha
----+--------------+---------------------------+------------
  1 | Ada Lovelace | Fundamentos de Docker     | 2026-09-23
  2 | Alan Turing  | Volumenes en contenedores | 2026-09-23
(2 rows)
```

Idénticas, **incluidos los `id` 1 y 2**. Ese detalle importa: significa que hasta el contador de
la secuencia `SERIAL` estaba en el volumen. No es que las filas se recuperaran — es que nunca
estuvieron en el contenedor.

### La contraprueba, sin volumen

```
ERROR:  relation "certificados" does not exist
LINE 1: SELECT * FROM certificados
                      ^
```

Y conviene leer **exactamente** qué error es. No dice que la base de datos `labdocker` no
exista: la base de datos **sí** existe, porque el `POSTGRES_DB=labdocker` hizo que `initdb` la
creara desde cero al arrancar. Lo que no existe es la tabla.

Eso es el mecanismo confesando: este contenedor inicializó **un directorio de datos virgen**,
porque no había ningún volumen que le dijera "aquí ya hay algo, sáltate la inicialización".

### La frontera del montaje

<<PEGA AQUÍ las dos salidas de `stat -c '%d %n'`, la del contenedor sin volumen (dos números
iguales) y la del contenedor con volumen (dos números distintos).>>

### El volumen, por dentro

```
$ docker volume inspect pgdata
[
    {
        "CreatedAt": "2026-09-23T13:39:19Z",
        "Driver": "local",
        "Labels": null,
        "Mountpoint": "/var/lib/docker/volumes/pgdata/_data",
        "Name": "pgdata",
        "Options": null,
        "Scope": "local"
    }
]
```

**Ese `Mountpoint` no existe en el Mac.** Existe dentro de la VM ligera en la que Docker Desktop
corre el motor. En una máquina Linux sí sería una ruta del anfitrión, abrible directamente. Es
la misma razón por la que `docker info` reporta 7,75 GiB de memoria y no la del ordenador.

## Errores con los que me topé

<<PEGA AQUÍ. Lo que salió de verdad en esta sesión, por si quieres partir de ello:

- `free -h` no existe en macOS: es de procps, de Linux. Y el número que de verdad importa no es
  la RAM de la máquina sino la del motor de Docker, que se ve con
  `docker info | grep -i "total memory"`.
- El demonio no estaba arrancado: `docker info` fallaba con `failed to connect to the docker API
  at unix:///Users/.../docker.sock`. Se arregla con `open -a Docker` y esperando medio minuto.
- Avisos de Alpine al inicializar, inofensivos: `sh: locale: not found` y
  `WARNING: no usable system locales were found`. Alpine es una distro mínima y no trae las
  configuraciones regionales completas; solo afectan al orden alfabético y al formato de fechas
  y números.
- `initdb: warning: enabling "trust" authentication for local connections`. Esperado, y explica
  por qué desde dentro del contenedor no hace falta contraseña y desde fuera sí.
- Intenté ver la frontera del montaje con `df -h / /var/lib/postgresql/data` y el resultado era
  ambiguo: el `df` de busybox (Alpine) agrupa por dispositivo y no daba fila propia a la ruta de
  datos, y encima mostraba `/etc/hostname`, que es uno de los tres ficheros que Docker monta
  aparte en todo contenedor. Lo repetí con `stat -c '%d %n'`, que compara números de dispositivo
  y no deja lugar a dudas.
- En zsh, el `!` dentro de comillas dobles dispara la expansión de historial y rompe la
  contraseña. Comillas simples.>>

## Qué queda pendiente a propósito

- **Los contenedores todavía no se hablan entre sí.** Aquí el cliente se ejecuta *dentro* del
  mismo contenedor, con `docker exec`. Que un contenedor **distinto** encuentre a este por su
  nombre es el [lab 06](../06-redes/), y es el otro concepto que Compose da por sabido.
- **La aplicación .NET todavía no toca esta base de datos.** Eso llega con Compose, en el
  [lab 07](../07-compose/).
- **Nada de esperas inteligentes.** Aquí hay `sleep 10` porque el motor tarda en aceptar
  conexiones. Lo correcto es un *healthcheck* y una dependencia condicionada; se ve en Compose,
  y entonces estos `sleep` desaparecen.
- **Copias de seguridad del volumen.** Un volumen no es una copia de seguridad: sobrevive al
  contenedor, no a su propio borrado. Respaldarlo es otro tema.
- **El secreto sigue en texto plano.** Consciente y documentado arriba.
- **No se ha probado el bind mount.** Se explica en el apunte y se usa en el lab 07 para meter
  un `init.sql`, que es su caso legítimo. Aquí no hacía falta.