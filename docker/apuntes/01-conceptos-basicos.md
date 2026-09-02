# 01 · Conceptos básicos: imagen, contenedor y puertos

> Los tres conceptos que hay que tener claros antes de escribir un solo comando.
> Si vienes de programación orientada a objetos, las analogías te van a encajar rápido.

---

## El problema que resuelve Docker

"En mi máquina funciona." Ese es el problema.

Una aplicación no es solo tu código: es tu código **más** el runtime, más las librerías del
sistema, más unas variables de entorno, más una versión concreta de todo eso. Cuando mueves
el código a otra máquina, mueves solo una parte, y el resto tiene que coincidir por
casualidad.

Docker empaqueta **todo el conjunto** en una unidad que se ejecuta igual en tu portátil,
en el de tu compañero y en un servidor.

---

## 1. Imagen

Una **imagen** es un paquete congelado y de **solo lectura** que contiene todo lo que tu
aplicación necesita para arrancar: el sistema de archivos, las dependencias, el runtime y
tu código ya compilado.

> 🧊 **Analogía:** una receta ya cocinada y metida al congelador. No se come tal cual: se
> saca una ración y se calienta.

Puntos que cuestan al principio:

- **Las imágenes no se ejecutan.** Se ejecutan copias suyas (los contenedores).
- **Son inmutables.** Si quieres cambiar algo, construyes una imagen nueva. No se "edita"
  una imagen existente.
- **Se identifican por `nombre:tag`**, por ejemplo `dockerlab:v1` o
  `mcr.microsoft.com/dotnet/sdk:8.0`. Si no pones tag, Docker asume `:latest`, que es una
  fuente inagotable de sorpresas: `latest` no significa "la última", significa "la que
  alguien etiquetó como latest".
- **Se construyen en capas.** Cada instrucción del Dockerfile añade una capa encima de la
  anterior. Esto importa para la caché (ver apunte 02).

Ver las que tienes: `docker images`

---

## 2. Contenedor

Un **contenedor** es una imagen puesta en marcha: un proceso aislado corriendo con el
sistema de archivos de esa imagen, su propia red y sus propios procesos.

> 🧬 **Analogía (la que mejor funciona viniendo de C#):**
> **la imagen es la clase, el contenedor es la instancia.**
> `docker run` es el `new`.

De una misma imagen puedes lanzar 1 o 50 contenedores. Todos arrancan idénticos y son
independientes entre sí: lo que uno escriba en su disco no lo ven los demás.

Puntos que cuestan al principio:

- **Un contenedor vive mientras viva su proceso principal.** Si el proceso termina, el
  contenedor se para. Por eso un contenedor con un `echo hola` "se muere" enseguida: no
  está roto, es que ya ha hecho su trabajo.
- **Borrar un contenedor no borra la imagen.** Por eso crear y destruir contenedores es
  barato: `docker rm` y vuelta a empezar.
- **Lo que escribas dentro de un contenedor se pierde al borrarlo**, salvo que uses
  volúmenes (eso es más adelante).

Ver los que corren: `docker ps` · Ver también los parados: `docker ps -a`

---

## ¿Y una máquina virtual no es lo mismo?

No, y la diferencia explica por qué Docker es rápido.

| | Máquina virtual | Contenedor |
|---|---|---|
| Qué incluye | Un sistema operativo **completo**, con su propio kernel | Solo tu app y sus dependencias |
| Kernel | El suyo | Comparte el del host |
| Arranque | Segundos o minutos | Milisegundos |
| Peso | Gigas | De megas a cientos de megas |

> 🏢 **Analogía:** una VM es una casa unifamiliar con sus propios cimientos e instalaciones.
> Un contenedor es un piso en un bloque: paredes propias, pero la estructura y las tuberías
> son compartidas.

---

## 3. Mapeo de puertos

Este es el concepto pequeño que te muerde el primer día.

Un contenedor tiene **su propia red aislada**. Si tu API escucha en el puerto 8080 *dentro*
del contenedor, desde tu máquina no la ves. Hay que abrir una puerta explícitamente:

```bash
docker run -p 8080:8080 mi-imagen
#            ^^^^ ^^^^
#            │    └── puerto DENTRO del contenedor
#            └─────── puerto en TU máquina (host)
```

**El de la izquierda es el tuyo, el de la derecha es el de dentro.** No tienen por qué
coincidir: `-p 9000:8080` significa "entra por el 9000 de mi PC y te llevo al 8080 del
contenedor".

> 🚪 **Analogía:** el contenedor es un edificio sin puertas al exterior. `-p` es abrir una
> puerta concreta y decir a qué habitación de dentro lleva.

Errores típicos:

- **"No me responde el localhost"** → casi siempre falta el `-p`, o la app dentro del
  contenedor escucha en un puerto distinto al que has mapeado.
- **"Bind for 0.0.0.0:8080 failed: port is already allocated"** → ese puerto ya está
  ocupado en tu máquina. Cambia **el de la izquierda**, no el de la derecha:
  `-p 8081:8080`.
- **La app escucha en `localhost` dentro del contenedor** → entonces solo se escucha a sí
  misma. En ASP.NET Core se arregla con `ASPNETCORE_URLS=http://+:8080` (el `+` significa
  "todas las interfaces").

---

## Resumen en tres líneas

1. **Imagen** = paquete congelado e inmutable. La clase.
2. **Contenedor** = imagen en ejecución, aislada y desechable. La instancia.
3. **`-p host:contenedor`** = la puerta entre tu máquina y el contenedor.

---

## Para leer más

- [Docker — What is a container](https://docs.docker.com/get-started/docker-concepts/the-basics/what-is-a-container/) (doc oficial, corto)
- [Docker — What is an image](https://docs.docker.com/get-started/docker-concepts/the-basics/what-is-an-image/)

➡️ Siguiente: [02 · Anatomía de un Dockerfile](02-anatomia-dockerfile.md)
