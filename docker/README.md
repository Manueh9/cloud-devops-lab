# 🐳 Docker

Primera parada de la ruta, y **completada**. Docker resuelve un problema muy concreto:
**empaquetar tu aplicación con todo lo que necesita para arrancar**, de forma que corra igual
en tu portátil, en el de un compañero y en un servidor de producción.

Es también el prerrequisito de casi todo lo que viene después: Kubernetes orquesta
contenedores, los pipelines de CI/CD construyen imágenes, y en la nube se despliegan
contenedores. Sin esto, lo demás no se sostiene.

> Los ejemplos usan una Web API de .NET porque es mi terreno, pero los conceptos son los
> mismos con cualquier lenguaje.

⬆️ [Volver a la portada del repo](../README.md)

---

## Apuntes (la teoría, en orden)

| # | Apunte | De qué va |
|---|---|---|
| 01 | [Conceptos básicos: imagen, contenedor y puertos](apuntes/01-conceptos-basicos.md) | Qué es cada cosa y por qué se confunden |
| 02 | [Anatomía de un Dockerfile](apuntes/02-anatomia-dockerfile.md) | Qué hace cada instrucción, línea a línea |
| 03 | [Chuleta de comandos](apuntes/03-chuleta-comandos.md) | Los comandos del día a día, con qué hace cada uno |
| 04 | [Multi-stage builds](apuntes/04-multi-stage.md) | Por qué la imagen pesa de más y cómo separar compilación de ejecución |
| 05 | [Imagen limpia: `.dockerignore`, env y no-root](apuntes/05-imagen-limpia.md) | Contexto de build, configuración fuera de la imagen y usuario sin privilegios |
| 06 | [Caché de capas](apuntes/06-cache-de-capas.md) | Capas, invalidación en cascada y `dotnet restore` adelantado |
| 07 | [Volúmenes](apuntes/07-volumenes.md) | Capa de escritura, volumen frente a bind mount, punto de montaje |
| 08 | [Redes](apuntes/08-redes.md) | Red propia con DNS interno, y por qué `-p` es solo para fuera |
| 09 | [Docker Compose](apuntes/09-compose.md) | Varios contenedores como un solo sistema: servicios, healthcheck y `down` vs `down -v` |

## Labs (un ejercicio por sesión)

| # | Lab | Qué se consigue | Estado |
|---|---|---|---|
| 01 | [Primera imagen con una API .NET](labs/01-primera-imagen-dotnet/) | Una Web API de .NET corriendo dentro de un contenedor construido por mí | ✅ Hecho |
| 02 | [Multi-stage build](labs/02-multi-stage/) | La misma API en una imagen que pesa una fracción de la del lab 01 | ✅ Hecho |
| 03 | [`.dockerignore`, env vars, usuario no-root](labs/03-imagen-limpia/) | Imagen más limpia y más segura | ✅ Hecho |
| 04 | [Caché de capas](labs/04-cache-de-capas/) | Builds mucho más rápidos aprovechando lo que Docker ya tiene hecho | ✅ Hecho |
| 05 | [Volúmenes](labs/05-volumenes/) | Que los datos sobrevivan a la destrucción del contenedor | ✅ Hecho |
| 06 | [Redes](labs/06-redes/) | Que dos contenedores se encuentren por nombre | ✅ Hecho |
| 07 | [Docker Compose](labs/07-compose/) | Levantar API .NET + BD con un solo comando | ✅ Hecho |

---

## Por dónde empezar si llegas de nuevas

Lee los apuntes 01 y 02, y en cuanto los entiendas haz el lab 01. Docker se entiende
haciéndolo: la primera vez que ves tu propia aplicación respondiendo desde dentro de un
contenedor, la mitad de los conceptos encajan solos.

A partir de ahí, los labs van de menos a más y cada uno se apoya en el anterior: una imagen
(01) → hacerla ligera (02) → limpia y segura (03) → rápida de construir (04) → con estado que
persiste (05) → hablando con otro contenedor (06) → y todo junto, orquestado con un fichero
(07). Ese último cierra el recorrido: una API .NET y su base de datos levantándose juntas con
un solo comando.

---

## Y ahora, ¿qué?

Docker está cerrado: sabes construir una imagen, adelgazarla, aprovechar la caché, guardar el
estado en un volumen, conectar contenedores por nombre y levantar el sistema entero con un
`docker compose up`.

Lo siguiente **no** es Kubernetes. Orquestar contenedores tiene sentido cuando ya hay un sitio
donde ponerlos y alguien que lo pague: por eso el paso siguiente es **[Azure](../azure/)** —
entender la nube, desplegar a mano y aprender a no gastar. Kubernetes llega más adelante, después
de automatizar el despliegue (CI/CD) y de describir la infraestructura como código (Terraform).