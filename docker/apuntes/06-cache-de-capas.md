# 06 · Caché de capas: por qué el orden del Dockerfile es diseño

> Anterior: [05 · Imagen limpia](05-imagen-limpia.md) · Siguiente: *(pendiente)*
> Lab que lo acompaña: [labs/04-cache-de-capas](../labs/04-cache-de-capas/)

Hasta ahora hemos mirado el Dockerfile como una receta: una lista de pasos que hay que dar
en un orden que funcione. Este apunte va de que **el orden no solo tiene que funcionar:
también decide cuánto tarda cada build**, y eso acaba siendo uno de los números que más se
notan cuando hay integración continua de por medio.

## 1. Las capas

Cada instrucción del Dockerfile crea una **capa**: un conjunto de cambios sobre el sistema de
ficheros de la capa anterior. La imagen es el apilamiento de todas ellas, y cada capa es
**inmutable**.

```bash
docker history dockerlab:v4
```

> **Analogía (C#).** Es la herencia: cada clase derivada añade cosas sobre la anterior sin
> poder modificarla. **Analogía (git).** Cada instrucción es un commit y la imagen es la
> rama: reescribir un commit de en medio obliga a rehacer todos los posteriores.

## 2. Cuándo se reutiliza una capa

Al construir, Docker va instrucción por instrucción preguntándose si ya tiene una capa hecha
con esa misma instrucción, sobre la misma capa anterior y con las mismas entradas. Si la
tiene, la reutiliza y lo anuncia con `CACHED` en la salida.

La regla que gobierna todo lo demás:

> **En cuanto una instrucción no puede aprovechar la caché, ninguna de las siguientes puede
> tampoco.**

No es pereza: las capas siguientes se construyeron *sobre* la que ha cambiado, así que ya no
son válidas.

> **Analogía.** Una fila de dominó. Si tiras la pieza 4, caen la 5, la 6 y la 7; la 1, la 2
> y la 3 siguen en pie. Todo el arte consiste en poner lo que cambia mucho al final de la
> fila.

Para una instrucción `COPY`, "las mismas entradas" quiere decir que el contenido de los
ficheros copiados no ha cambiado. De ahí que el `.dockerignore` del apunte anterior sea un
requisito previo de este: si `bin/` y `obj/` viajan en el contexto, cambian en cuanto
compilas en local y tiran la caché en cada build aunque no hayas tocado nada relevante.

## 3. El problema del orden ingenuo

```dockerfile
COPY . .
RUN dotnet publish -c Release -o /app/out
```

Cambias una letra de un `.cs`, la capa del `COPY` cambia, cae el dominó y el `publish` se
rehace entero: compilación **y restauración de todos los paquetes NuGet**, que es la parte
lenta y la única que necesita red. Y eso pese a que las dependencias no habían cambiado:
están declaradas en el `.csproj`, un fichero que se toca muy de vez en cuando.

## 4. La solución: separar los dos ritmos

```dockerfile
COPY *.csproj ./
RUN dotnet restore
COPY . .
RUN dotnet publish -c Release -o /app/out --no-restore
```

Ahora hay dos bloques con vidas distintas: el de las dependencias (arriba, cambia poco) y el
del código (abajo, cambia constantemente). Al tocar un `.cs`, las capas del `.csproj` y del
`restore` se mantienen y solo se rehace de ahí para abajo.

El `--no-restore` no es decorativo: sin él, `dotnet publish` vuelve a restaurar por su cuenta
y el ahorro desaparece por completo.

> **Analogía.** Las dependencias cambian una vez al mes; el código, veinte veces al día.
> Meterlos en la misma caja significa pagar el precio mensual veinte veces cada día.

## 5. Medición

| Escenario | Orden ingenuo | Restore adelantado |
|---|---|---|
| Build limpio (`--no-cache`) | ~7.0s | ~11.0s |
| Rebuild sin cambios | ~0.7s | ~0.3s |
| Rebuild tocando un `.cs` | ~6.1s | ~2.0s |

En el build limpio los dos tardan parecido (incluso la v4 salió algo más lenta por ruido de
red de esa restauración concreta), y tiene sentido: sin caché hay que hacerlo todo igualmente,
así que ahí no hay ningún truco que gane. La diferencia aparece en la tercera fila, que es el
caso que se repite decenas de veces al día: en el orden ingenuo, tocar una línea de código
cuesta lo mismo que un build limpio (6.1s) porque `restore` y `publish` van en la misma
instrucción; con el `restore` adelantado, esa misma línea de código solo cuesta 2.0s porque la
capa del `RUN dotnet restore` sigue en pie (`CACHED`) y solo se rehace el `publish`.

## 6. Lo que NO arregla esto

La caché vive en la máquina que construye. En un servidor de integración continua, cada
ejecución puede empezar con la caché vacía, y entonces la tercera fila de la tabla se parece
a la primera. Existen mecanismos para exportar y reutilizar la caché entre ejecuciones, pero
son tema de otro momento: primero hay que tener el Dockerfile bien ordenado, porque sin eso
ninguna caché sirve de nada.

## 7. Errores típicos

- **Olvidar el `--no-restore` en el `publish`.** Sin él, `dotnet publish` vuelve a restaurar
  por su cuenta al final, y todo el truco de adelantar el `restore` no sirve de nada: se paga
  dos veces.
- **Copiar el código antes que el `.csproj`, o todo junto.** Si el `COPY . .` va antes del
  `COPY *.csproj ./` (o si se hace un único `COPY . .` seguido de `restore`), la capa del
  `restore` vuelve a depender de todo el código y se invalida en cada cambio, exactamente el
  problema que se quería evitar.
- **Proyectos con referencias a otros proyectos (`ProjectReference`).** `COPY *.csproj ./` solo
  copia el `.csproj` de la carpeta actual; si la solución tiene varios proyectos, `dotnet
  restore` falla porque no encuentra los `.csproj` referenciados. Hay que copiar la estructura
  de carpetas de todos los `.csproj` implicados antes del `restore`, no solo uno suelto.
- **Un `.dockerignore` que no excluye `bin/`, `obj/` o `.vs/`.** Si esas carpetas viajan en el
  contexto, cambian cada vez que compilas en local y el `COPY *.csproj ./` o el `COPY . .`
  siguientes se invalidan aunque no hayas tocado ni una línea de código ni de dependencias.
- **Sacar conclusiones de una sola medición.** Los tiempos de build tienen ruido (red, CPU
  compartida con otros procesos); conviene repetir cada escenario un par de veces antes de dar
  por buena una comparación, sobre todo en el build limpio con `--no-cache`.
- **Confundir la caché local con la de un pipeline de CI/CD.** Un `--no-cache` en tu máquina
  todavía tiene las imágenes base ya descargadas si las usaste antes; un runner de CI que
  arranca en limpio paga también esa descarga. El ahorro de reordenar el Dockerfile sigue
  aplicando, pero el número absoluto no es comparable sin más.
