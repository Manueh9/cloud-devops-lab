# Azure

Docker enseñó a empaquetar una aplicación. Azure es el sitio donde esa aplicación vive: la nube
donde se crean los recursos, se despliega el código y —a diferencia de Docker— se paga por lo que
se usa.

Esta carpeta recorre Azure desde cero: primero el andamiaje (qué cajas hay y cómo se anidan),
después la terminal (`az`, para que lo hecho sea repetible) y después el primer despliegue real.
El criterio es siempre el mismo: **primero a mano para entenderlo, después escrito para repetirlo.**

Todo esto es también la práctica que sostiene la certificación **AZ-104** (Azure Administrator
Associate).

## Apuntes

| # | Apunte | De qué va |
|---|---|---|
| 01 | [El andamiaje de Azure](apuntes/01-el-andamiaje-de-azure.md) | Suscripción, grupo de recursos y recurso; la región; y por qué el grupo es la unidad de borrado |

## Labs

| # | Lab | Qué se hace | Estado |
|---|---|---|---|
| 01 | [Primer grupo de recursos](labs/01-primer-grupo-de-recursos/) | Crear un grupo y un Storage Account en el portal, subir un blob, poner una alerta de gasto y borrarlo todo | ✅ Completo |

## La regla de esta carpeta

> **Un lab = un grupo de recursos = un borrado al terminar.**

Docker era gratis; Azure no. Cada lab crea su propio grupo de recursos y lo borra entero al
acabar. Un recurso olvidado no avisa: cobra en silencio.

## Antes de empezar, si llegas de fuera

Necesitas una cuenta de Azure. Las dos vías gratuitas son
[Azure for Students](https://azure.microsoft.com/en-us/free/students) (requiere correo académico,
sin tarjeta) y la [cuenta gratuita](https://azure.microsoft.com/en-us/free/) normal (requiere
teléfono y tarjeta no prepago). Pon un presupuesto con alerta el primer día — ten en cuenta que
una suscripción recién creada necesita 48 horas antes de admitir presupuestos.