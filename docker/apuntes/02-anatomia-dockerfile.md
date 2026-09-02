# 02 · Anatomía de un Dockerfile

> Un Dockerfile es la **receta escrita** para fabricar una imagen.
> `docker build` la cocina. `docker run` sirve una ración.

El fichero se llama `Dockerfile`, sin extensión, y normalmente vive en la raíz de la
carpeta del proyecto.

---

## El Dockerfile del lab 01, línea a línea

Este es el primero que escribí. Es **deliberadamente simple y nada optimizado**: mete el
SDK entero dentro de la imagen final. Eso se arregla en el lab 02; aquí lo importante es
entender qué hace cada instrucción.

```dockerfile
FROM mcr.microsoft.com/dotnet/sdk:8.0

WORKDIR /app

COPY . .

RUN dotnet publish -c Release -o out

ENV ASPNETCORE_URLS=http://+:8080

ENTRYPOINT ["dotnet", "out/DockerLab.dll"]
```

### `FROM` — de qué partes

```dockerfile
FROM mcr.microsoft.com/dotnet/sdk:8.0
```

Toda imagen se construye **encima de otra**. Aquí partimos de una imagen oficial de
Microsoft que ya trae el SDK de .NET instalado, así que no tengo que instalar nada.

- `mcr.microsoft.com` → el registro de Microsoft (el equivalente a Docker Hub para sus
  imágenes).
- `:8.0` → el tag. Ajústalo al SDK que tengas: comprueba con `dotnet --list-sdks`.

> Es siempre la primera instrucción. Sin `FROM` no hay imagen.

### `WORKDIR` — en qué carpeta trabajas dentro

```dockerfile
WORKDIR /app
```

Fija el directorio de trabajo **dentro del contenedor** para las instrucciones siguientes
(y para cuando arranque). Si no existe, lo crea.

Equivale a hacer `cd /app`, pero persistente: no hace falta repetirlo.

### `COPY` — meter tus archivos dentro

```dockerfile
COPY . .
```

Copia archivos **desde tu máquina hacia la imagen**. Los dos puntos son:

- El primero: origen, relativo al **contexto de build** (la carpeta que le pasas a
  `docker build`, normalmente `.`).
- El segundo: destino dentro de la imagen, relativo al `WORKDIR`.

⚠️ `COPY . .` copia **todo**, incluidos `bin/`, `obj/` y `.git` si están ahí. Es feo y
engorda la imagen. Se arregla con un `.dockerignore` (lab 03).

### `RUN` — ejecutar comandos **al construir**

```dockerfile
RUN dotnet publish -c Release -o out
```

Ejecuta un comando **durante el build** y guarda el resultado como una capa nueva de la
imagen. Aquí es donde se compila la aplicación.

> Distinción clave: `RUN` se ejecuta al **construir** la imagen. `ENTRYPOINT`/`CMD` se
> ejecutan al **arrancar** el contenedor. Confundirlos es el error número uno.

### `ENV` — variables de entorno

```dockerfile
ENV ASPNETCORE_URLS=http://+:8080
```

Define una variable de entorno que existirá dentro del contenedor. Esta en concreto le dice
a ASP.NET Core en qué URL escuchar.

El `+` significa **"todas las interfaces de red"**. Si pusieras `localhost`, la app solo se
escucharía a sí misma dentro del contenedor y desde fuera no responderías ni con `-p`.

### `ENTRYPOINT` — qué se ejecuta al arrancar

```dockerfile
ENTRYPOINT ["dotnet", "out/DockerLab.dll"]
```

El proceso principal del contenedor. **Mientras este proceso viva, el contenedor vive.**
Cuando termina, el contenedor se para.

La forma con corchetes (*exec form*) es la recomendada: ejecuta el binario directamente,
sin una shell por medio, y así las señales del sistema (por ejemplo el `Ctrl+C` o el
`docker stop`) llegan bien a tu aplicación.

---

## Las capas y la caché (la idea, sin entrar en detalles)

Cada instrucción del Dockerfile crea una **capa**. Docker las cachea: si reconstruyes y una
instrucción y todo lo anterior no ha cambiado, reutiliza la capa en vez de rehacerla.

La consecuencia práctica: **el orden importa**. Lo que cambia poco (instalar dependencias)
va arriba; lo que cambia en cada commit (tu código) va abajo. Si pones tu código arriba,
invalidas la caché de todo lo de debajo en cada build.

En este Dockerfile no lo he aprovechado: `COPY . .` copia el código antes de restaurar
paquetes, así que cada cambio recompila todo. Es otra de las cosas que se arreglan en el
lab 02.

---

## Instrucciones que aún no he usado (para que suenen)

| Instrucción | Para qué |
|---|---|
| `CMD` | Argumentos por defecto, sobrescribibles al hacer `docker run` |
| `EXPOSE` | Documenta qué puerto usa la imagen (no abre nada por sí solo) |
| `USER` | Ejecutar como un usuario que no sea root |
| `ARG` | Variable disponible solo durante el build |
| `LABEL` | Metadatos (autor, versión…) |

---

## Para leer más

- [Dockerfile reference](https://docs.docker.com/reference/dockerfile/) (doc oficial)
- [Building best practices](https://docs.docker.com/build/building/best-practices/) — para
  cuando ya domines lo básico

⬅️ Anterior: [01 · Conceptos básicos](01-conceptos-basicos.md) ·
➡️ Siguiente: [03 · Chuleta de comandos](03-chuleta-comandos.md)
