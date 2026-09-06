# ☁️ cloud-devops-lab — Aprendiendo Cloud y DevOps desde cero

---

## Cómo está organizado
 
```
cloud-devops-lab/
├── app/                → la aplicación de ejemplo. Siempre la misma, para todos los labs
│   └── DockerLab/      → una Web API de .NET recién generada, sin nada especial
└── <tecnología>/       → docker/, y más adelante kubernetes/, terraform/, cicd/…
    ├── README.md       → índice de esa tecnología: apuntes, labs y estado
    ├── apuntes/        → la teoría, numerada y en orden (01-, 02-, 03-…)
    └── labs/           → un ejercicio por sesión (01-nombre/, 02-nombre/…), con su README
```
 
**Una carpeta por tecnología.** Cada una es autocontenida y sigue siempre esa misma
estructura, así que puedes entrar directamente por la que te interese y leerla de arriba
abajo, sin que se te mezcle con las demás.
 
**Y una sola aplicación, en `app/`.** Es deliberado: lo que cambia de un lab a otro no es la
aplicación, es lo que le hacemos. La misma Web API se empaqueta (Docker), se orquesta
(Kubernetes) y se despliega (CI/CD). Así el esfuerzo se va a la herramienta nueva y no a
entender otra aplicación distinta cada vez.

---

## Ruta de aprendizaje

El orden no es casual: cada tecnología se apoya en la anterior. Empaquetar la aplicación
(Docker) es el prerrequisito de orquestarla (Kubernetes); no tiene sentido automatizar el
despliegue (CI/CD) de algo que aún no sabes desplegar a mano.

| # | Tecnología | Para qué sirve | Estado |
|---|---|---|---|
| 1 | [**Docker**](docker/) | Empaquetar la aplicación y sus dependencias en una imagen que corre igual en cualquier sitio | 🟢 En curso |
| 2 | **Kubernetes** | Orquestar muchos contenedores: escalado, reinicios, despliegues sin caída | 🔜 Pendiente |
| 3 | **Terraform** | Definir la infraestructura como código, en vez de a base de clicks en un panel | 🔜 Pendiente |
| 4 | **CI/CD** | Que compilar, testear y desplegar ocurra solo en cada push | 🔜 Pendiente |
| 5 | **Azure** | La nube donde acaba corriendo todo lo anterior | 🔜 Pendiente |
| 6 | **Observabilidad** | Logs, métricas y trazas: saber qué está pasando ahí dentro | 🔜 Pendiente |

Cada carpeta aparece en el repo cuando arranca su bloque.

---

## Requisitos para seguir los labs

- Docker instalado y funcionando (`docker run hello-world` debe responder).
- SDK de .NET (cada lab indica el tag de imagen que usa).
- Una máquina donde no importe romper cosas. Yo uso una VM de VirtualBox con Ubuntu Server.

---

## Otros repos de esta serie

Este repo es uno de tres, montados con la misma estructura de "asignatura":

| Repo | De qué va |
|---|---|
| [`cloud-devops-lab`](https://github.com/Manueh9/cloud-devops-lab) | Este: Docker, Kubernetes, Terraform, CI/CD, Azure, observabilidad |
| [`security-lab`](https://github.com/Manueh9/security-lab) | Seguridad web: PortSwigger Web Security Academy y OWASP Juice Shop |
| [`ml-lab`](https://github.com/Manueh9/ml-lab) | IA/ML con Python: datos, modelos y llevarlos a producción |

---

## Licencia

[MIT](LICENSE) — usa estos apuntes para lo que quieras.
