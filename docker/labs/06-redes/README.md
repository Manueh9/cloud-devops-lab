# Lab 06 · Redes: dos contenedores que se encuentran por nombre

> Anterior: [lab 05 · Volúmenes](../05-volumenes/) · Siguiente: *(pendiente — Docker Compose)*
> Teoría: [apuntes/08-redes.md](../../apuntes/08-redes.md)

## Objetivo

Conseguir que un contenedor **cliente** consulte una base de datos que corre en **otro**
contenedor, llamándola **por su nombre** y **sin que esta publique ningún puerto** hacia el
anfitrión. Y demostrarlo con dos contrapruebas: que el mismo comando falla fuera de la red, y que
al recrear el servidor su IP cambia mientras el nombre sigue funcionando.

Como el [lab 05](../05-volumenes/), este no tiene `Dockerfile`: es un lab de comandos. Los dos
son el escalón previo a Docker Compose, que no hace más que automatizarlos.

## Entorno

```
Plataforma      macOS (Darwin), Apple Silicon (arm64)
Motor de BD     postgres:16-alpine
Sesión          24 y 25 de septiembre de 2026
```

## Higiene antes de empezar

El primer `docker run` de la sesión falló:

```
docker: Error response from daemon: Conflict. The container name "/basedatos" is already in use
by container "dffceb85bfd26910aafe0861e6bec81212cdb1e16028c2b113076d334494184b".
You have to remove (or rename) that container to be able to reuse that name.
```

Era el contenedor del [lab 05](../05-volumenes/), que se quedó sin limpiar. **Los nombres de
contenedor son únicos en todo el motor**, independientemente de en qué red estén o de si están
parados. Y un contenedor **no se mueve de red**: el de antes estaba en la red por defecto, así
que no valía reutilizarlo — hay que borrarlo y crear otro dentro de `labnet`.

De ahí una costumbre que conviene coger:

```bash
docker ps -a
docker volume ls
docker network ls
```

## Pasos reproducibles

### 1. Crear la red

```bash
docker network create labnet
docker network ls
```

En `docker network ls` aparecen también `bridge`, `host` y `none`: las tres vienen de fábrica.

### 2. Levantar la base de datos DENTRO de la red y SIN publicar puerto

```bash
docker run -d \
  --name basedatos \
  --network labnet \
  -v pgdata:/var/lib/postgresql/data \
  -e POSTGRES_PASSWORD='Docker!Lab2026' \
  -e POSTGRES_DB=labdocker \
  postgres:16-alpine

sleep 10
docker ps
```

**No hay `-p`.** Es deliberado, y es la mitad de la lección: la columna `PORTS` de `docker ps`
sale vacía y aun así el cliente del paso 4 llega.

### 3. Crear los datos

```bash
sql_dentro() {
  docker exec -e PGPASSWORD='Docker!Lab2026' basedatos \
    psql -U postgres -d labdocker -c "$1"
}

sql_dentro "CREATE TABLE IF NOT EXISTS certificados (id SERIAL PRIMARY KEY, alumno TEXT, curso TEXT, fecha DATE)"
sql_dentro "INSERT INTO certificados (alumno, curso, fecha) VALUES
            ('Ada Lovelace','Fundamentos de Docker','2026-09-24'),
            ('Alan Turing','Redes en contenedores','2026-09-24')"
```

Este paso usa `docker exec`, es decir, el cliente **dentro del mismo contenedor**. Es hacer
trampa a propósito: evita justo el problema que resuelve el lab. El cliente de verdad es el del
paso siguiente.

### 4. Consultar desde OTRO contenedor, por nombre

```bash
docker run --rm \
  --network labnet \
  -e PGPASSWORD='Docker!Lab2026' \
  postgres:16-alpine \
  psql -h basedatos -U postgres -d labdocker -c "SELECT * FROM certificados"
```

- `-h basedatos` es el **nombre del otro contenedor**, no una IP.
- `--rm` hace que el cliente se autodestruya al terminar: un contenedor de usar y tirar.
- La base de datos **no publica ningún puerto** y el cliente llega igual, porque comparten red.

### 5. La prueba negativa

El mismo comando, quitando solo `--network labnet`:

```bash
docker run --rm \
  -e PGPASSWORD='Docker!Lab2026' \
  postgres:16-alpine \
  psql -h basedatos -U postgres -d labdocker -c "SELECT * FROM certificados"
```

Debe fallar al traducir el nombre. Dos comandos idénticos salvo una bandera, uno funciona y el
otro no: eso es lo que convierte la observación del paso 4 en una demostración.

### 6. La IP cambia, el nombre no

Aquí hay que montar el experimento con cuidado, y merece explicarse porque el montaje **es** parte
de lo aprendido.

Docker asigna siempre **la dirección libre más baja** de la subred. Si se borra el único
contenedor de la red y se recrea, le vuelve a tocar la misma IP, y el experimento no demostraría
nada. Así que se mete un contenedor de paja que ocupe la dirección anterior mientras se recrea la
base de datos:

```bash
# Anotar la IP actual
docker network inspect labnet --format '{{range .Containers}}{{.Name}} {{.IPv4Address}}{{"\n"}}{{end}}'

docker rm -f basedatos

# Un contenedor cualquiera se queda con la direccion que acaba de quedar libre
docker run -d --name ocupante --network labnet alpine sleep 600

# Recrear la base de datos: ahora le toca otra
docker run -d --name basedatos --network labnet \
  -v pgdata:/var/lib/postgresql/data \
  -e POSTGRES_PASSWORD='Docker!Lab2026' -e POSTGRES_DB=labdocker \
  postgres:16-alpine
sleep 10

docker network inspect labnet --format '{{range .Containers}}{{.Name}} {{.IPv4Address}}{{"\n"}}{{end}}'
```

Y repetir el cliente del paso 4 **sin cambiar una sola letra**.

```bash
docker rm -f ocupante
```

### 7. Ver el mecanismo del DNS

```bash
docker exec basedatos cat /etc/resolv.conf
```

### 8. Limpieza

```bash
docker rm -f basedatos
docker volume rm pgdata
docker network rm labnet
```

## Resultado real

### La red que crea Docker

```json
{
    "Name": "labnet",
    "Created": "2026-09-25T14:43:01.266642213Z",
    "Scope": "local",
    "Driver": "bridge",
    "IPAM": {
        "Config": [
            {
                "Subnet": "172.18.0.0/16",
                "Gateway": "172.18.0.1"
            }
        ]
    },
    "Status": {
        "IPAM": {
            "Subnets": {
                "172.18.0.0/16": {
                    "IPsInUse": 4,
                    "DynamicIPsAvailable": 65532
                }
            }
        }
    }
}
```

Dos lecturas de ahí:

- La subred es la **`172.18.0.0/16`**. La red `bridge` de fábrica es la `172.17.0.0/16`: cada red
  propia se lleva la siguiente libre. `labnet` es la primera red definida por el usuario que
  existe en este motor.
- `IPsInUse: 4` con un solo contenedor dentro no es un error: se cuentan la dirección de red
  (`172.18.0.0`), la puerta de enlace (`172.18.0.1`), la de difusión y la del contenedor. Al ser
  una `/16`, quedan 65.532 libres.

### El cliente, en otro contenedor, consultando por nombre

```
 id |    alumno    |           curso           |   fecha
----+--------------+---------------------------+------------
  1 | Ada Lovelace | Fundamentos de Docker     | 2026-09-23
  2 | Alan Turing  | Volumenes en contenedores | 2026-09-23
  3 | Ada Lovelace | Fundamentos de Docker     | 2026-09-24
  4 | Alan Turing  | Redes en contenedores     | 2026-09-24
(4 rows)
```

Las filas 1 y 2 tienen fecha
del **23/09**: se crearon en el [lab 05](../05-volumenes/), en otro contenedor, en otra red, en
otra sesión. Entre medias el contenedor se borró varias veces y Docker Desktop se reinició. Las
filas 3 y 4 son de este lab.

O sea: el volumen `pgdata` ha sobrevivido **a varios `docker rm -f` y reinicios del
motor**. Eso es lo que significa que un volumen tenga ciclo de vida propio, y se ve mejor aquí, sin
buscarlo, que en el experimento que se montó para demostrarlo.

### La IP cambia, el nombre no

Antes de recrear:

```
basedatos 172.18.0.2/16
```

Después de recrear, con la `.2` ocupada por el contenedor de paja:

```
ocupante 172.18.0.2/16
basedatos 172.18.0.3/16
```

Y el cliente del paso 4, **con el mismo comando exacto**, siguió devolviendo las cuatro filas. La
base de datos está en otra dirección y a quien la usa le da igual: pregunta por el nombre.

> **Por qué hizo falta el contenedor de paja.** Sin él, Docker le habría vuelto a asignar la
> `172.18.0.2` a la base de datos recreada, porque reparte siempre la dirección libre más baja, y
> el experimento no habría demostrado nada. El montaje es parte de lo aprendido: **un resultado
> que sale igual con y sin la causa no es una prueba.**

### El DNS interno

```
➜  cloud-devops-lab git:(main) ✗ docker exec basedatos cat /etc/resolv.conf
# Generated by Docker Engine.
# This file can be edited; Docker Engine will not make further changes once it
# has been modified.

nameserver 127.0.0.11
options ndots:0

# Based on host file: '/etc/resolv.conf' (internal resolver)
# ExtServers: [host(192.168.65.7)]
# Overrides: []
# Option ndots from: internal
```

## Errores con los que me topé

- El conflicto de nombre al empezar, por no haber limpiado el contenedor del lab 05. Los nombres
  son únicos en todo el motor y un contenedor no se mueve de red: hay que borrarlo y recrearlo.
- El paso de la IP no demostraba nada tal como estaba planteado, porque Docker reasignaba la misma
  dirección. Hubo que ocupar la dirección anterior con otro contenedor para que se viera.
- El `INSERT` se ejecutó sobre un volumen que ya tenía las filas del lab 05, así que la tabla
  acabó con cuatro filas y dos fechas distintas. No es un fallo: acabó siendo la mejor prueba de
  persistencia del repo.>>

## Qué queda pendiente a propósito

- **La aplicación .NET todavía no habla con esta base de datos.** El cliente de este lab es el
  `psql` de la propia imagen de PostgreSQL, no la API. Conectar la API es el lab de Compose.
- **Todo esto sigue siendo a mano**: crear la red, crear el volumen, dos `docker run` largos que
  hay que recordar y escribir en orden. Docker Compose existe exactamente para eso, y por eso se
  ve **después** de este lab y no antes.
- **Nada de esperas inteligentes**: aquí hay `sleep 10` porque el motor tarda en aceptar
  conexiones. Lo correcto es un *healthcheck* y una dependencia condicionada, y se ve en Compose.
- **Aislamiento entre redes**: no he probado qué pasa con varias redes a la vez, ni con un
  contenedor conectado a dos, ni `docker network connect` sobre un contenedor ya arrancado.
- **Nada de redes de varios anfitriones** (`overlay`, `macvlan`). Eso es mundo Kubernetes.
- **El secreto sigue en texto plano.** Igual que en el lab 05, y por la misma razón: es un
  laboratorio local que se destruye al terminar.