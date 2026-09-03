# 🐳 Docker

Primera parada de la ruta. Docker resuelve un problema muy concreto: **empaquetar tu
aplicación con todo lo que necesita para arrancar**, de forma que corra igual en tu portátil,
en el de un compañero y en un servidor de producción.

Es también el prerrequisito de casi todo lo que viene después: Kubernetes orquesta
contenedores, los pipelines de CI/CD construyen imágenes, y en la nube se despliegan
contenedores. Sin esto, lo demás no se sostiene.

> Los ejemplos usan una Web API de .NET porque es mi terreno, pero los conceptos son los
> mismos con cualquier lenguaje. Donde una analogía de programación orientada a objetos
> ayuda, la uso.

⬆️ [Volver a la portada del repo](../README.md)

---

## Apuntes (la teoría, en orden)

| # | Apunte | De qué va |
|---|---|---|
| 01 | [Conceptos básicos: imagen, contenedor y puertos](apuntes/01-conceptos-basicos.md) | Qué es cada cosa y por qué se confunden |
| 02 | [Anatomía de un Dockerfile](apuntes/02-anatomia-dockerfile.md) | Qué hace cada instrucción, línea a línea |
| 03 | [Chuleta de comandos](apuntes/03-chuleta-comandos.md) | Los comandos del día a día, con qué hace cada uno |
| 04 | [Multi-stage builds](apuntes/04-multi-stage.md) | Por qué la imagen pesa de más y cómo separar compilación de ejecución |

## Labs (un ejercicio por sesión)

| # | Lab | Qué se consigue | Estado |
|---|---|---|---|
| 01 | [Primera imagen con una API .NET](labs/01-primera-imagen-dotnet/) | Una Web API de .NET corriendo dentro de un contenedor construido por mí | ✅ Hecho |
| 02 | [Multi-stage build](labs/02-multi-stage/) | La misma API en una imagen que pesa una fracción de la del lab 01 | ✅ Hecho |
| 03 | `.dockerignore`, variables de entorno y usuario no-root | Imagen más limpia y más segura | ⏳ Siguiente |
| 04 | Caché de capas | Builds mucho más rápidos aprovechando lo que Docker ya tiene hecho | 🔜 |
| 05 | Volúmenes y redes | Que los datos sobrevivan al contenedor y que dos contenedores se hablen | 🔜 |
| 06 | Docker Compose | Levantar API .NET + SQL Server con un solo comando | 🔜 |

---

## Por dónde empezar si llegas de nuevas

Lee los apuntes 01 y 02, y en cuanto los entiendas haz el lab 01. Docker se entiende
haciéndolo: la primera vez que ves tu propia aplicación respondiendo desde dentro de un
contenedor, la mitad de los conceptos encajan solos.

➡️ Siguiente tecnología de la ruta: Kubernetes (aún no empezada)