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
| 02 | [La terminal: Azure CLI](apuntes/02-azure-cli.md) | `az`, la forma de los comandos, el MFA, nombres únicos y por qué ser dueño no da acceso a los datos |
| 03 | [App Service](apuntes/03-app-service.md) | PaaS, que por debajo es un contenedor; plan contra web app; el nivel F1; dónde se termina el TLS y dónde se compila el código |
| 04 | [Redes: VNet y NSG](apuntes/04-redes-vnet-nsg.md) | La red privada y sus subredes, las reglas por prioridad, las seis reglas por defecto y qué sobrevive a borrar una VM |
| 05 | [Entra ID y RBAC](apuntes/05-entra-id-rbac.md) | Las tres piezas de un permiso, los ámbitos, por qué los permisos suman y gestión frente a datos |

## Labs

| # | Lab | Qué se hace | Estado |
|---|---|---|---|
| 01 | [Primer grupo de recursos](labs/01-primer-grupo-de-recursos/) | Crear un grupo y un Storage Account en el portal, subir un blob, poner una alerta de gasto y borrarlo todo | ✅ Completo |
| 02 | [Los mismos recursos, desde la terminal](labs/02-az-cli/) | Grupo, storage, contenedor y blob con `az`, en dos scripts que se repiten | ✅ Completo |
| 03 | [La API .NET en App Service](labs/03-app-service/) | Desplegar con `az webapp up` y después con las cuatro piezas por separado; quién compila, quién nombra y quién factura | ✅ Completo |
| 04 | [VNet y NSG](labs/04-vnet-y-nsg/) | Red privada con dos subredes y un NSG; la prioridad de las reglas y qué sobrevive a borrar una VM | 📘 Teórico |
| 05 | [Entra ID y RBAC](labs/05-entra-id-y-rbac/) | Un grupo de Entra ID con tres roles en tres ámbitos, y qué puede hacer en cada escalón | 📘 Teórico |

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