# Lab 04 · Caché de capas

## Objetivo

Medir cuánto tarda reconstruir la imagen cuando cambia una línea de código, reordenar el
Dockerfile para adelantar `dotnet restore`, y volver a medir. El entregable es una tabla
comparativa con tiempos reales.

Teoría detrás de este lab: [apuntes/06-cache-de-capas.md](../../apuntes/06-cache-de-capas.md)


## Requisitos

- Haber hecho el [lab 03](../03-imagen-limpia/): el `.dockerignore` es condición previa.
- Ejecutar todo **desde la raíz del repositorio**.

## Pasos reproducibles

### 1. Ver las capas de la imagen actual

```bash
docker history dockerlab:v3
```

### 2. Medir el orden ingenuo (lab 03)

```bash
time docker build --no-cache -f docker/labs/03-imagen-limpia/Dockerfile -t dockerlab:v3 app/DockerLab
time docker build           -f docker/labs/03-imagen-limpia/Dockerfile -t dockerlab:v3 app/DockerLab

echo "// cambio para probar la cache" >> app/DockerLab/Program.cs
time docker build           -f docker/labs/03-imagen-limpia/Dockerfile -t dockerlab:v3 app/DockerLab
```

### 3. Medir con `restore` adelantado

```bash
time docker build --no-cache -f docker/labs/04-cache-de-capas/Dockerfile -t dockerlab:v4 app/DockerLab
time docker build           -f docker/labs/04-cache-de-capas/Dockerfile -t dockerlab:v4 app/DockerLab

echo "// segundo cambio para probar la cache" >> app/DockerLab/Program.cs
time docker build           -f docker/labs/04-cache-de-capas/Dockerfile -t dockerlab:v4 app/DockerLab
```

En esta última salida, la línea del `dotnet restore` debe aparecer como `CACHED`.

### 4. Comprobar que la imagen sigue siendo válida

```bash
docker run -d --name api4 -p 8083:8080 dockerlab:v4
docker exec api4 whoami
curl http://localhost:8083/weatherforecast
docker rm -f api4
```

### 5. Dejar el código como estaba

```bash
git checkout -- app/DockerLab/Program.cs
```

## Resultado real

| Escenario | v3 (orden ingenuo) | v4 (restore adelantado) |
|---|---|---|
| Build limpio (`--no-cache`) | ~7.0s (`dotnet publish` 6.1s) | ~11.0s (`dotnet restore` 8.6s) |
| Rebuild sin cambios | ~0.7s (todo `CACHED`) | ~0.3s (todo `CACHED`) |
| Rebuild tocando un `.cs` | ~6.1s (`COPY . .` y `publish` NO cacheados) | ~2.0s (**`restore` CACHED**, solo `publish` 1.6s) |

El build limpio de la v4 salió más lento que el de la v3 (11s vs 7s), pero es ruido de red de
esa restauración concreta (Mac recién migrado, sin caché local de NuGet todavía), no un
defecto del reordenamiento: con `--no-cache` los dos parten de cero y ahí no hay truco que
gane. La fila que demuestra el concepto es la tercera: al tocar una línea de código, la v3
paga lo mismo que un build limpio (6.1s) porque `restore` y `publish` van pegados, mientras
que la v4 se queda en 2.0s porque el `restore` ya estaba cacheado.

Fragmento de la salida del último build de la v4, con el `restore` cacheado:

```
#8 [build 3/6] COPY *.csproj ./
#8 CACHED

#9 [build 2/6] WORKDIR /src
#9 CACHED

#10 [build 4/6] RUN dotnet restore
#10 CACHED

#11 [build 5/6] COPY . .
#11 DONE 0.0s

#12 [build 6/6] RUN dotnet publish -c Release -o /app/out --no-restore
#12 1.543   DockerLab -> /src/bin/Release/net8.0/DockerLab.dll
#12 1.562   DockerLab -> /app/out/
#12 DONE 1.6s
```

## Errores con los que me topé

- Al migrar el repo a un Mac nuevo no tenía ni Docker Desktop arrancado ni la imagen
  `dockerlab:v3` construida localmente. Hubo que arrancar Docker Desktop y reconstruir la v3
  desde el `Dockerfile` del lab 03 antes de poder medir nada, porque las imágenes construidas
  no viajan con el repo (solo el código fuente de los Dockerfiles).
- `ls app/DockerLab/*.csproj` me fallaba con un error sobre `--icons`: es un alias roto en mi
  `.zshrc` (probablemente `ls` apuntando a `eza`/`exa` con una flag mal puesta), no un problema
  de Docker ni del proyecto. Confirmé la ruta del `.csproj` leyendo el directorio directamente.
- El primer build limpio de cualquiera de las dos versiones en esta máquina paga también la
  descarga de las imágenes base (`dotnet/sdk:8.0` y `dotnet/aspnet:8.0`). Hice un
  `docker pull` de ambas antes de medir para que el `--no-cache` reflejara solo el coste de
  `restore`/`publish`, y no la descarga de red de las imágenes base.

## Qué queda pendiente a propósito

- **La caché en un servidor de integración continua**, que empieza vacía en cada ejecución.
  Se puede exportar y reutilizar, pero eso es tema del bloque de CI/CD.
- **Reducir aún más la imagen final** (imágenes `alpine`, `chiseled`, compilación AOT). Son
  optimizaciones; primero hay que tener lo básico sólido.

⬅️ Anterior: [lab 03 · Imagen limpia](../03-imagen-limpia/) 
➡️ Siguiente: *(pendiente)*
🏠 [Índice de Docker](../../README.md) · [Portada del repo](../../../README.md)
