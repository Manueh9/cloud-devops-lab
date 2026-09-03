# 04 · Multi-stage builds: por qué tu imagen pesa 10 veces más de lo que debería

En el [apunte 02](02-anatomia-dockerfile.md) escribimos un Dockerfile con un solo `FROM`.
Funcionaba, pero producía una imagen enorme. Aquí vemos por qué, y cómo se arregla.

---

## El problema: compilar y ejecutar necesitan cosas distintas

Para **compilar** una aplicación .NET hace falta el **SDK**: el compilador de C#, MSBuild,
NuGet, las plantillas de proyecto, los analizadores. Son cientos de megabytes de
herramientas.

Para **ejecutar** el resultado no hace falta nada de eso. Solo hace falta el **runtime**:
el motor de .NET y las librerías base.

El Dockerfile del lab 01 partía de la imagen del SDK y se quedaba ahí. Resultado: la imagen
final llevaba dentro todo el taller de compilación, que después de compilar no sirve
absolutamente para nada.

> **Analogía:** para fabricar una estantería necesitas sierra, taladro y banco de trabajo.
> Para usar la estantería solo necesitas la estantería. Publicar una imagen construida así
> es entregar el mueble con el taller entero atornillado detrás.
>
> **Si vienes de C#:** el SDK es Visual Studio y el compilador. El runtime es lo que
> instala tu usuario para poder abrir el `.exe`. A nadie se le ocurre mandarle Visual
> Studio al cliente.

Y no es solo cuestión de disco. Una imagen más pequeña se sube y se baja más rápido en un
pipeline de CI/CD, y expone menos software instalado, o sea menos superficie de ataque.

---

## La solución: varias etapas en un mismo Dockerfile

Un Dockerfile puede tener **más de un `FROM`**. Cada `FROM` abre una **etapa** (*stage*)
nueva, que arranca desde cero con su propio sistema de archivos.

La regla que lo explica todo:

> **Solo la última etapa se convierte en tu imagen. Las anteriores se usan durante el build
> y se descartan.**

A las etapas se les pone nombre con `AS`, para poder referirse a ellas después:

```dockerfile
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build     # etapa 1: el taller
FROM mcr.microsoft.com/dotnet/aspnet:8.0           # etapa 2: el producto final
```

> **Analogía:** una mudanza. En la casa vieja lo sacas todo, lo revisas y lo empaquetas
> (etapa `build`). Al camión solo subes las cajas que te llevas, no los armarios ni el
> destornillador con el que los desmontaste (etapa final).

---

## El puente entre etapas: `COPY --from=`

Si la última etapa empieza de cero, hay que traer explícitamente lo que se compiló antes:

```dockerfile
COPY --from=build /app/out .
```

Se lee: *"copia, desde la etapa llamada `build`, la carpeta `/app/out`, y déjala aquí"*.

Lo decisivo es que **tú eliges qué cruza el puente**. El código fuente, las carpetas `obj/`
y `bin/`, los paquetes NuGet descargados y el SDK entero se quedan en la etapa `build` y no
aparecen por ningún lado en la imagen final.

> **Si vienes de C#:** una etapa se comporta como un método. Dentro hay variables locales y
> objetos temporales; cuando termina, fuera solo sale lo que devuelves con `return`.
> `COPY --from=build` es ese `return`.

---

## El Dockerfile completo

```dockerfile
# ─────────────── ETAPA 1: BUILD ───────────────
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /app
COPY . .
RUN dotnet publish -c Release -o /app/out

# ─────────────── ETAPA 2: RUNTIME ───────────────
FROM mcr.microsoft.com/dotnet/aspnet:8.0
WORKDIR /app
COPY --from=build /app/out .
ENV ASPNETCORE_URLS=http://+:8080
ENTRYPOINT ["dotnet", "DockerLab.dll"]
```

### Dos detalles que hacen fallar el primer intento

**1. La ruta del `ENTRYPOINT` cambia respecto al lab 01.** Allí era `out/DockerLab.dll`,
porque el publicado colgaba de `/app/out`. Aquí copiamos el *contenido* de `/app/out`
directamente a `/app`, así que la DLL queda en `/app/DockerLab.dll` y el entrypoint pasa a
ser `["dotnet", "DockerLab.dll"]`. Si no lo cambias, el contenedor arranca y muere al
instante con `Could not execute because the specified file was not found`.

**2. `aspnet`, no `runtime`.** Microsoft publica dos imágenes de runtime:

| Imagen | Para qué |
|---|---|
| `mcr.microsoft.com/dotnet/runtime` | Aplicaciones de consola |
| `mcr.microsoft.com/dotnet/aspnet` | Aplicaciones web (incluye ASP.NET Core) |

Una Web API necesita `aspnet`. Con `runtime` la imagen se construye, pero la app falla al
levantar el servidor web.

Y las dos etapas deben usar **la misma versión** de .NET: no compiles con SDK 9 para
ejecutar sobre runtime 8.

---

## Un extra que te ahorrará tiempo: `--target`

Como cada etapa tiene nombre, puedes construir solo hasta una de ellas:

```bash
docker build --target build -t dockerlab:solo-build .
```

Sirve para depurar: te deja una imagen con el taller intacto para entrar a mirar qué se
compiló y dónde quedó.

---

## Ejercicio

Coge el Dockerfile de una sola etapa del lab 01 y conviértelo en multi-stage tú mismo,
sin mirar el de arriba. Luego compara los tamaños con `docker images`.

Pistas: necesitas dos `FROM`, un `AS`, un `COPY --from=` y cambiar una ruta.

<details>
<summary>Ver solución</summary>

```dockerfile
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /app
COPY . .
RUN dotnet publish -c Release -o /app/out

FROM mcr.microsoft.com/dotnet/aspnet:8.0
WORKDIR /app
COPY --from=build /app/out .
ENV ASPNETCORE_URLS=http://+:8080
ENTRYPOINT ["dotnet", "DockerLab.dll"]
```

La ruta que había que cambiar es la del `ENTRYPOINT`: de `out/DockerLab.dll` a
`DockerLab.dll`.

</details>

---

## Lo que NO hemos hecho a propósito

- **No hemos cacheado la restauración de paquetes.** El tutorial oficial de Microsoft copia
  primero el `.csproj`, hace `dotnet restore` y luego copia el resto, para que Docker
  reutilice la capa de paquetes entre builds. Es una optimización de caché de capas y va en
  su propio apunte.
- **No hemos añadido `.dockerignore`**, así que ahora mismo estamos copiando también las
  carpetas `bin/` y `obj/` de la máquina a la etapa de build. No acaba en la imagen final,
  pero ensucia y ralentiza. Apunte 05.
- **Seguimos ejecutando como root** dentro del contenedor. Apunte 05 también.
- **No hemos probado imágenes `alpine` ni `chiseled`**, que reducen aún más el tamaño a
  cambio de complicaciones. Primero conviene dominar lo básico.

---

⬅️ Anterior: [03 · Chuleta de comandos](03-chuleta-comandos.md)
➡️ Siguiente: (pendiente) 05 · `.dockerignore`, variables de entorno y usuario no-root
🧪 Lab que aplica este apunte: [02 · Multi-stage build](../labs/02-multi-stage/)