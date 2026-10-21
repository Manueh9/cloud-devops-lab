# 04 · Redes en Azure: VNet, subredes y grupos de seguridad de red

> Anterior: [03 · App Service](03-app-service.md) · Siguiente: *(pendiente)*
> Lab que lo acompaña: [labs/04-vnet-y-nsg](../labs/04-vnet-y-nsg/)

Los apuntes anteriores iban de **dónde** vive una aplicación. Este va de **quién puede llegar a
ella**. Es la parte de Azure que más pesa en la certificación AZ-104 y la que conecta de forma más
directa con la seguridad: una red bien puesta es la primera capa de defensa, antes de que el código
tenga ocasión de equivocarse.

## 1. VNet y subredes

Una **red virtual (VNet)** es un rango de direcciones IP privadas propio dentro de Azure. Dentro
se crean **subredes**, que son trozos de ese rango.

```
VNet  10.10.0.0/16          65.536 direcciones
├── snet-web    10.10.1.0/24
└── snet-datos  10.10.2.0/24
```

El prefijo (`/16`, `/24`) indica cuántos bits de la dirección son fijos: cuantos más, menos
direcciones libres.

**Azure reserva cinco direcciones de cada subred**: *"Azure reserves the first four addresses and
the last address, for a total of five IP addresses within each subnet."* En un `/24` quedan 251
usables. La `.0` es la red, la `.1` la puerta de enlace, la `.2` y `.3` el DNS de Azure y la última
el broadcast. La subred más pequeña admitida es `/29`; la mayor, `/2`.

> **Analogía (C#).** La VNet es el *namespace* y las subredes son las clases de dentro: el
> namespace reserva un espacio propio donde no se choca con nadie, y lo de dentro se ve entre sí
> sin ceremonia.

Conviene elegir rangos que no se parezcan a la red doméstica (`192.168.1.x`): usar `10.10.x.x` en
Azure evita colisiones el día que haya una VPN de por medio.

## 2. El grupo de seguridad de red

Un **NSG** filtra el tráfico: *"You can use an Azure network security group to filter network
traffic between Azure resources in Azure virtual networks."*

Cada regla tiene nombre, **prioridad (100-4096)**, origen, destino, protocolo, dirección, rango de
puertos y acción (*Allow* o *Deny*).

La frase que gobierna todo el comportamiento:

> *"Rules are processed in priority order, with lower numbers processed before higher numbers
> because lower numbers have higher priority. Once traffic matches a rule, processing stops."*

De ahí lo contraintuitivo: **número más bajo manda**, y **la especificidad no cuenta**. Una
denegación amplia en la prioridad 90 gana a un permiso concreto en la 100, porque la 90 se evalúa
antes y el procesamiento se detiene.

> **Analogía (C#).** Un NSG es un bloque de `if` con `return` en cada rama, ordenado por
> prioridad, y con un `return Deny` final que no se puede borrar. No hay caída en cascada: el
> primer `return` que se alcanza es el veredicto.

## 3. Las reglas por defecto

Todo NSG nace con seis reglas que no se pueden eliminar (*"You can't remove the default rules, but
you can override them by creating rules with higher priorities"*):

| Dirección | Prioridad | Nombre | Efecto |
|---|---|---|---|
| Entrante | 65000 | `AllowVNetInBound` | Pasa el tráfico de dentro de la VNet |
| Entrante | 65001 | `AllowAzureLoadBalancerInBound` | Pasa el balanceador de Azure |
| Entrante | 65500 | `DenyAllInBound` | Se deniega todo lo demás |
| Saliente | 65000 | `AllowVnetOutBound` | Pasa hacia dentro de la VNet |
| Saliente | 65001 | `AllowInternetOutBound` | Pasa hacia internet |
| Saliente | 65500 | `DenyAllOutBound` | Se deniega todo lo demás |

Resumido:

```
de fuera hacia dentro  →  cerrado por defecto
de dentro hacia fuera  →  abierto por defecto
```

> Esta tabla es la de la documentación oficial. El lab que acompaña al apunte es teórico: muestra
> los comandos y la salida esperada, sin ejecutar.

## 4. Dos sitios donde puede colgar un NSG

Un NSG puede asociarse **a una subred** o **a la tarjeta de red de una máquina**. Para el tráfico
entrante se evalúa primero el de la subred y después el de la tarjeta: **si cualquiera de los dos
deniega, el paquete se descarta**.

Es el origen del error más común del tema: la regla está puesta, se ve en el portal y no funciona,
porque el otro NSG la está tapando. La práctica recomendada es poner la política en la subred —una
por zona de la red— en vez de una por máquina.

## 5. Un NSG que deniega no contesta

Una conexión bloqueada por NSG **no da "conexión rechazada": se queda colgada hasta agotar el
tiempo**. El paquete se descarta en silencio. Es intencionado: responder confirmaría que hay algo
al otro lado.


## 6. Dónde enlaza con el resto

- Con **ciberseguridad**: denegar por defecto y conceder lo mínimo es el mismo principio que
  `[Authorize]` en cada endpoint. Esconder no es proteger, ni una URL ni un puerto.
- Con **Terraform** (Fase 2): una VNet con sus subredes y sus reglas es el ejemplo canónico de
  infraestructura como código. Lo escrito hoy a mano es lo que después se describe en un `.tf`.
- Con **AKS** (Fase 2): un clúster de Kubernetes vive dentro de una VNet y sus subredes. Esto es el
  cimiento.