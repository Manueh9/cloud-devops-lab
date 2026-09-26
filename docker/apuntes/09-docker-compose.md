# 09 · Docker Compose: varios contenedores como un solo sistema

> Anterior: [08 · Redes](08-redes.md) · Siguiente: *(pendiente — empieza Kubernetes)*
> Lab que lo acompaña: [labs/07-compose](../labs/07-compose/)

Los dos apuntes anteriores resolvieron a mano las dos preguntas que tiene cualquier aplicación
de varias piezas: **dónde vive el estado** (volúmenes) y **cómo se encuentran las piezas**
(redes). Compose no añade ninguna idea nueva: **automatiza esas dos**, y les pone encima un
ciclo de vida común.

Por eso este apunte va el último de Docker y no el primero. Quien empieza por aquí copia un
YAML; quien llega por aquí lo lee.

## 1. Un servicio es la receta de un contenedor

En el fichero se declaran **servicios**: qué imagen usar o cómo construirla, qué variables de
entorno, qué volúmenes, qué puertos. Compose lee eso y crea los contenedores.

> **Analogía (C#).** Si la imagen es la clase y el contenedor la instancia, el servicio es el
> registro del contenedor de dependencias: `AddScoped<IRepositorio, RepositorioSql>()`. No es
> la clase ni la instancia: es la instrucción de cómo crearla. Por eso de un servicio pueden
> salir varios contenedores.

## 2. La red la crea Compose, y el nombre del servicio es el nombre de host

Compose crea una red propia para el proyecto y mete dentro todos los servicios. **El nombre
del servicio en el YAML es el nombre de host.** Eso es exactamente lo mismo que crear una red
con `docker network create` y arrancar los contenedores con `--network`, escrito en dos
palabras.

De ahí que la cadena de conexión de la API pudiera decir `Host=basedatos` y funcionar, sin IP
ninguna. Comprobado en el lab: desde el contenedor de la API, `getent hosts basedatos` devolvió
`172.18.0.2 basedatos`. Nadie escribió esa IP en ningún sitio.

## 3. `depends_on` ordena, el healthcheck garantiza

`depends_on` decide el **orden de arranque**, pero "arrancado" no es "listo": un motor de base
de datos tarda unos segundos más en aceptar conexiones. Si la aplicación se conecta al
arrancar, se estrella.

La solución son dos piezas juntas: un `healthcheck` en el servicio dependido, y `depends_on`
con `condition: service_healthy`. Eso sustituye a los `sleep` de los labs anteriores, que eran
una muleta consciente. En el `up` se ve el efecto: Compose espera a que `basedatos` esté
`Healthy` **antes** de arrancar `api`.

> **Analogía.** `depends_on` a secas es "abre la tienda antes que el almacén". El healthcheck
> es "y no dejes entrar a nadie hasta que el almacenero conteste al teléfono".

## 4. `down` frente a `down -v`

| Comando | Borra contenedores y red | Borra volúmenes |
|---|---|---|
| `docker compose down` | sí | **no** |
| `docker compose down -v` | sí | **sí** |

La diferencia entre las dos es, literalmente, el apunte de los volúmenes convertido en una
letra. En el lab se ve con las dos consultas del final: tras `down` y volver a levantar, las
filas siguen; tras `down -v` y volver a levantar, la tabla existe pero está vacía.

## 5. Volumen nombrado y bind mount conviven, cada uno en lo suyo

En el lab de este apunte hay los dos a la vez, y es la mejor forma de ver que la regla no era
"el bind mount es malo":

- los **datos** del motor van en un **volumen nombrado** (`pgdata`), porque deben persistir y
  porque los permisos los prepara Docker;
- el fichero **`init.sql`** entra por **bind mount de solo lectura**, porque es configuración
  propia que se quiere meter dentro del contenedor.

## 6. `docker compose config`, la herramienta que nadie usa

Devuelve el fichero **ya resuelto**: rutas absolutas, valores por defecto, variables
sustituidas. Antes de pelearse con un error de rutas o de interpolación, conviene mirarlo.

Y una que le acompaña, para no perderse: **`docker compose ls`** lista los proyectos Compose
vivos con la ruta completa de su fichero de configuración. El contenedor vive en el motor, no
en la carpeta; pero Compose guarda de qué carpeta nació, y estos dos comandos lo recuperan.

## 7. Lo que costó

Lo que de verdad me mordió no fue el YAML, fue **desde dónde lo ejecuté**. Escribí el
`docker-compose.yml` estando en la raíz del repositorio en vez de en la carpeta del lab, así
que las rutas relativas (`../../../app/DockerLab`, `./init.sql`) se resolvieron **tres niveles
más arriba de lo que debían**, y el build falló con `path not found`.

Lo que lo salvó fue mirar `docker compose config` **antes** del `--build`: ahí vi que el
`context` apuntaba a `/Users/.../app/DockerLab` en vez de a
`/Users/.../cloud-devops-lab/app/DockerLab`, y me ahorré esperar un build de varios minutos
para nada.

La lección, que no olvido: **las rutas relativas de un compose se resuelven respecto a dónde
vive el fichero, no respecto a dónde estás tú.** `docker compose` se ejecuta desde la carpeta
del `docker-compose.yml`.