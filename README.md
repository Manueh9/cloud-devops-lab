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

| # | Tecnología | Para qué sirve | Estado |
|---|---|---|---|
| 1 | [Docker](docker/) | Empaquetar la aplicación y sus dependencias en una imagen que corre igual en cualquier sitio | ✅ Completo |
| 2 | [Azure](azure/) | La nube donde viven los recursos: dónde se despliega, cuánto cuesta y cómo se apaga | 🔄 En curso |
| 3 | CI/CD | Compilar, probar y desplegar solo, en cada commit | ⏳ Pendiente |
| 4 | Terraform | Describir la infraestructura en código en vez de crearla a clics | ⏳ Pendiente |
| 5 | Kubernetes | Orquestar muchos contenedores: escalado y despliegues sin corte | ⏳ Pendiente |
| 6 | Observabilidad | Logs, métricas y trazas para saber qué hace el sistema por dentro | ⏳ Pendiente |

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
