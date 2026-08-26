# 🐳 docker-lab — Aprendiendo Docker desde cero

Apuntes y laboratorios de mi aprendizaje de **Docker**, escritos mientras lo aprendo.
Vengo de C#/.NET y en Cloud/DevOps empiezo de cero, así que todo está explicado como me
habría gustado que me lo explicaran a mí: **primero el concepto en lenguaje llano, después
el comando**.

> Si estás empezando con Docker, este repo te sirve. No hay nada avanzado aquí: hay
> lo básico, bien explicado y probado en una máquina real.

---

## Cómo usar este repo

- **`apuntes/`** → la teoría, en orden. Léelos seguidos si empiezas de cero.
- **`labs/`** → los ejercicios prácticos, uno por sesión. Cada lab es una carpeta
  autocontenida con su propio README: objetivo, pasos, resultado y los errores con los
  que me topé.

Cada lab se puede reproducir tal cual: clona, entra en la carpeta y sigue su README.

---

## Índice

### Apuntes

| # | Apunte | De qué va |
|---|---|---|
| 01 | [Conceptos básicos: imagen, contenedor y puertos](apuntes/01-conceptos-basicos.md) | Qué es cada cosa y por qué se confunden |
| 02 | [Anatomía de un Dockerfile](apuntes/02-anatomia-dockerfile.md) | Qué hace cada instrucción, línea a línea |
| 03 | [Chuleta de comandos](apuntes/03-chuleta-comandos.md) | Los comandos del día a día, con qué hace cada uno |

### Labs

| # | Lab | Qué se consigue | Estado |
|---|---|---|---|
| 01 | [Primera imagen con una API .NET](labs/01-primera-imagen-dotnet/) | Una Web API de .NET corriendo dentro de un contenedor construido por mí | ✅ Hecho |
| 02 | Multi-stage build | Reducir el tamaño de la imagen separando compilación y ejecución | ⏳ Siguiente |
| 03 | `.dockerignore`, variables de entorno y usuario no-root | Imagen más limpia y más segura | 🔜 |
| 04 | Volúmenes y redes | Que los datos sobrevivan al contenedor y que dos contenedores se hablen | 🔜 |
| 05 | Docker Compose | Levantar API .NET + SQL Server con un solo comando | 🔜 |

---

## Requisitos para seguir los labs

- Docker instalado y funcionando (`docker run hello-world` debe responder).
- SDK de .NET (yo uso el que tenga instalado; cada lab indica el tag de imagen).
- Ganas de romper cosas en una máquina que no importe. Yo uso una VM de VirtualBox.

---

## Por qué existe este repo

Estoy siguiendo un plan de estudio semanal de Cloud/DevOps: **Docker → Kubernetes →
Terraform → CI/CD → Azure → Observabilidad**. Un bloque por semana, un solo paso pequeño
cada vez. Escribir los apuntes es parte del método: si no soy capaz de explicarlo, es que
no lo he entendido.

Si algo está mal explicado o directamente equivocado, abre un issue. Se agradece.

---

## Licencia

[MIT](LICENSE) — usa estos apuntes para lo que quieras.
