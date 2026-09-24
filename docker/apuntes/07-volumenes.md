# 07 · Volúmenes: dónde vive el estado

> Anterior: [06 · Caché de capas](06-cache-de-capas.md) · Siguiente: [08 · Redes](08-redes.md)
> Lab que lo acompaña: [labs/05-volumenes](../labs/05-volumenes/)

Los apuntes anteriores trataban de construir **una** imagen lo más limpia y lo más rápida
posible. Este cambia de asunto: ya no va de construir, va de **qué pasa con lo que el
contenedor escribe mientras corre**.

Es el primer apunte de este repositorio que trata a un contenedor como parte de un sistema y
no como una pieza aislada.

---

## 1. La capa de escritura es desechable

Un contenedor arranca desde una imagen, que es **de solo lectura**, y le añade encima una
**capa de escritura** propia. Todo lo que el proceso de dentro escriba —un fichero, una fila
en una tabla, una línea de log— va a parar a esa capa.

Y esa capa **desaparece cuando el contenedor se borra**.

Eso no es un defecto: es el diseño. Un contenedor está pensado para ser desechable y
reemplazable, y justamente por eso sirve para desplegar: si algo va mal, se tira y se levanta
otro idéntico. El problema aparece cuando lo que corre dentro **es** estado, como una base de
datos. Si el estado muere con el contenedor, no hay base de datos: hay un juguete.

> **Analogía (C#).** La capa de escritura equivale a las **variables locales de un método**:
> viven mientras dura la llamada y se las lleva el recolector al salir. Si algo tiene que
> sobrevivir a la llamada, ha de estar **fuera** del método — en un campo, en un fichero, en
> una base de datos. Un volumen es ese "fuera".

---

## 2. Volumen nombrado y bind mount

Docker ofrece dos formas de sacar datos fuera del contenedor:

| | Volumen nombrado | Bind mount |
|---|---|---|
| Sintaxis | `-v datos:/ruta/dentro` | `-v /ruta/del/host:/ruta/dentro` |
| Dónde vive | Zona gestionada por Docker | Una carpeta concreta del anfitrión |
| Permisos | Los prepara Docker | Los gestionas tú |
| Uso típico | Datos que deben persistir: bases de datos, ficheros subidos | Desarrollo: montar el código fuente dentro; ficheros de configuración |

La forma rápida de distinguirlos leyendo un comando ajeno: **si la parte izquierda del `:`
empieza por `/` o por `.`, es una ruta**, y por tanto es un bind mount; si es un nombre suelto,
es un volumen nombrado.

> **Analogía.** El volumen nombrado es un **trastero que alquila y gestiona Docker**: no sabes
> en qué estantería está tu caja, pero está bien puesta y con los permisos correctos. El bind
> mount es **prestar una habitación de tu casa**: sabes exactamente dónde está, pero el follón
> de permisos es tuyo.

Para una base de datos se usa volumen nombrado, y no solo por teoría: el proceso de dentro del
contenedor corre con un usuario propio, y con un bind mount en Linux es muy fácil acabar en un
`Permission denied` sobre el directorio de datos.

Eso **no** convierte al bind mount en el hermano malo. Tiene su caso y es otro: meter dentro
del contenedor un fichero propio, normalmente de configuración y de solo lectura. Los dos
conviven en el lab de Docker Compose, cada uno en lo suyo.

---

## 3. Cómo funciona por debajo: el punto de montaje

Aquí está el mecanismo, que es lo que de verdad hay que entender y lo que casi nunca se
explica.

Un contenedor no tiene "un" sistema de ficheros: tiene **varios apilados**.

1. Las **capas de la imagen**, de solo lectura, una sobre otra.
2. Encima, la **capa de escritura** del contenedor. Cuando un proceso modifica un fichero que
   venía de la imagen, la imagen no se toca: se hace una copia en esta capa y se escribe ahí.
   Eso se llama *copy-on-write*, y es lo que permite que cien contenedores compartan la misma
   imagen sin estorbarse.
3. Y **encima de todo eso**, los montajes que se hayan pasado con `-v`.

El tercer punto es la clave. `-v pgdata:/var/lib/postgresql/data` **no copia nada**: le dice al
núcleo que la ruta `/var/lib/postgresql/data` de ese contenedor **no forma parte de sus capas**,
que ahí hay montado otro sistema de ficheros.

Así que cuando PostgreSQL escribe una fila, hace una escritura sobre esa ruta como si fuera un
directorio cualquiera —ni sabe ni le importa que sea un volumen— y esos bytes **nunca pasan por
la capa de escritura del contenedor**. Salen directos al volumen.

> **Analogía (C#).** La capa de escritura son las variables locales. El volumen es **un objeto
> inyectado por el constructor**: escribes en `_repositorio.Guardar(x)` sin saber dónde vive
> ese repositorio, y su vida no depende de la tuya. Cuando el método termina, tus locales se
> van; el repositorio sigue, porque nunca fue tuyo. `docker rm` es tu método terminando.

De ahí que la frase correcta no sea *"los datos se recuperaron"* sino **"los datos nunca
estuvieron en el contenedor"**. Se estaba escribiendo fuera desde el primer `INSERT`.

### La prueba de la frontera

Comparando el número de dispositivo de dos rutas dentro del mismo contenedor se ve si hay
montaje o no. Mismo número, mismo sistema de ficheros, ninguna frontera:

```bash
docker exec <contenedor> stat -c '%d %n' / /var/lib/postgresql/data
```

Con volumen los dos números son distintos; sin volumen, iguales. Es la forma menos ambigua de
verlo — más fiable que `df`, que en Alpine viene de busybox y agrupa por dispositivo en vez de
dar una fila por argumento.

### Por qué el motor no reinicializó los datos

La segunda mitad del mecanismo la pone la propia imagen, no Docker. El guion de arranque de
`postgres` comprueba si el directorio de datos ya está inicializado (busca el fichero
`PG_VERSION`):

- **Directorio vacío** → ejecuta `initdb`, crea la base de datos del `POSTGRES_DB`, aplica la
  contraseña del `POSTGRES_PASSWORD` y deja en los logs un `PostgreSQL init process complete`.
- **Directorio con datos** → **se salta la inicialización entera** y arranca sobre lo que hay.

Eso explica tres cosas de golpe:

1. Que en los logs del contenedor recreado **no aparezcan** las líneas de `initdb`.
2. Que las claves de la secuencia `SERIAL` sigan en 1 y 2: el contador también estaba en el
   volumen.
3. Que **la contraseña del `-e` se ignore cuando el volumen ya tenía datos** — manda la que se
   guardó el primer día. Es la causa del clásico `password authentication failed` al reutilizar
   un volumen viejo.

---

## 4. Un volumen no es una copia de seguridad

Un volumen sobrevive al **contenedor**, no a su propio borrado: `docker volume rm` se lleva los datos igual. Respaldar
un volumen es otro tema y tiene sus propias herramientas.

---

## 5. El motor de base de datos, y por qué este

Este lab se hizo con **PostgreSQL 16 (Alpine)**. El motivo fue **la arquitectura**: la
máquina es un Mac con Apple Silicon (`arm64`), y la imagen oficial `mcr.microsoft.com/mssql/server`
solo se publica para `amd64`. Habría que emularla, con la lentitud y los fallos que eso trae.

La propia base de datos lo confirma en su primera línea de log:

```
PostgreSQL 16.15 on aarch64-unknown-linux-musl, compiled by gcc (Alpine 15.2.0) 15.2.0, 64-bit
```

`aarch64` es arm64: imagen **nativa** para el chip. Y `musl` confirma que es la variante Alpine.

---

## 6. Un matiz de macOS y Windows

`docker volume inspect` devuelve un `Mountpoint` así:

```
/var/lib/docker/volumes/pgdata/_data
```

En una máquina Linux esa ruta es del anfitrión y se puede abrir. **En macOS y en Windows no
existe en el ordenador**: existe dentro de la VM ligera en la que Docker Desktop corre el motor,
que a su vez vive dentro de un fichero de imagen de disco. No se puede abrir con el Finder.

No cambia nada de lo que se aprende, pero explica por qué la carpeta "no está" — y explica
también por qué `docker info` reporta una memoria que no es la del ordenador: es la de esa VM.

---

## 7. Errores con los que me topé

- `free -h` no existe en macOS (es de procps, de Linux). El número que importa además no es la
  RAM de la máquina sino la del motor de Docker: `docker info | grep -i "total memory"`.
- El demonio no estaba arrancado y `docker info` fallaba con `failed to connect to the docker
  API at unix:///.../docker.sock`. Se arregla con `open -a Docker` y esperando.
- Avisos de Alpine al inicializar: `sh: locale: not found` y `WARNING: no usable system locales
  were found`. Inofensivos para el lab: Alpine es mínima y no trae las configuraciones
  regionales completas; solo afectan al orden alfabético y al formato de fechas y números.
- `initdb: warning: enabling "trust" authentication for local connections`. También esperado, y
  útil de entender: por eso desde dentro del contenedor no hace falta contraseña, y desde fuera
  sí.
- Intenté ver la frontera del montaje con `df -h` y el resultado era ambiguo, porque el `df` de
  busybox agrupa por dispositivo y no daba fila propia a la ruta de datos. Lo repetí con
  `stat -c '%d %n'`, que compara números de dispositivo y no deja lugar a dudas.