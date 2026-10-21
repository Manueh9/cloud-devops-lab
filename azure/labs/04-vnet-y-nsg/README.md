# Lab 04 · VNet y NSG: quién puede entrar

> Anterior: [lab 03 · La API .NET en App Service](../03-app-service/)
> Teoría: [apuntes/04-redes-vnet-y-nsg.md](../../apuntes/04-redes-vnet-y-nsg.md)

> 📘 **Lab teórico.** Los comandos son los reales y reproducibles, pero no se han ejecutado en esta
> cuenta. Lo que aparece como **salida esperada** es lo que la documentación oficial de Azure dice
> que debe ocurrir; no es una salida copiada de una terminal.

## Objetivo

Montar una red privada en Azure con dos subredes, poner un grupo de seguridad de red (NSG) en la
subred de delante y entender con una máquina de prueba que **el acceso lo decide la regla, no la
aplicación**: el mismo servidor, encendido todo el rato, es inalcanzable o alcanzable según lo que
diga el NSG.

Y, de paso, ver qué recursos sobreviven a `az vm delete`, que es la razón por la que en esta
carpeta todo se borra por grupo.

## Lo que se monta

```
VNet  vnet-lab04   10.10.0.0/16
├── snet-web     10.10.1.0/24   ← con el NSG nsg-web asociado
│   └── vm-web   (Standard_B1s, Ubuntu, sin NSG en la tarjeta de red)
└── snet-datos   10.10.2.0/24   ← vacía, para ver que una subred es un recurso aparte
```

## Ficheros

| Fichero | Para qué |
|---|---|
| [`crear-lab.sh`](crear-lab.sh) | Monta todo el lab de una vez: grupo, VNet, subredes, NSG, regla SSH y VM |
| [`borrar-lab.sh`](borrar-lab.sh) | Borra el grupo entero, que es la única limpieza fiable |

Los dos están escritos a partir de la documentación oficial y **sin probar contra Azure**; la
sintaxis está comprobada con `bash -n`.

## Variables

```bash
GRUPO="rg-lab04-redes"
REGION="francecentral"
VNET="vnet-lab04"
NSG="nsg-web"
VM="vm-web"
```

## Paso 1 — La red (gratis)

```bash
az group create --name "$GRUPO" --location "$REGION" --output table

az network vnet create --resource-group "$GRUPO" --name "$VNET" \
    --address-prefixes 10.10.0.0/16 \
    --subnet-name snet-web --subnet-prefixes 10.10.1.0/24 --output table

az network vnet subnet create --resource-group "$GRUPO" --vnet-name "$VNET" \
    --name snet-datos --address-prefixes 10.10.2.0/24 --output table

az network vnet subnet list --resource-group "$GRUPO" --vnet-name "$VNET" --output table
```

**Salida esperada:** dos subredes, `snet-web` con `10.10.1.0/24` y `snet-datos` con `10.10.2.0/24`,
las dos en estado `Succeeded`. La segunda se crea con un comando aparte para dejar claro que una
subred es un recurso propio dentro de la VNet.

Cada `/24` tiene 256 direcciones, pero Azure se queda 5 (la `.0`, la `.1`, la `.2`, la `.3` y la
última), así que quedan **251 usables** por subred.

## Paso 2 — El NSG y sus seis reglas por defecto

```bash
az network nsg create --resource-group "$GRUPO" --name "$NSG" --output table

az network nsg rule list --resource-group "$GRUPO" --nsg-name "$NSG" --output table
az network nsg rule list --resource-group "$GRUPO" --nsg-name "$NSG" --include-default --output table
```

**Salida esperada:** el primer `rule list` sale **vacío**, porque no has escrito ninguna regla. El
segundo, con `--include-default`, muestra **seis**. Están desde el momento en que se crea el NSG y
no se pueden borrar:

| Dirección | Prioridad | Nombre | Acceso |
|---|---|---|---|
| Entrante | 65000 | `AllowVNetInBound` | Allow |
| Entrante | 65001 | `AllowAzureLoadBalancerInBound` | Allow |
| Entrante | 65500 | `DenyAllInBound` | Deny |
| Saliente | 65000 | `AllowVnetOutBound` | Allow |
| Saliente | 65001 | `AllowInternetOutBound` | Allow |
| Saliente | 65500 | `DenyAllOutBound` | Deny |

Entre `DenyAllInBound` y `AllowInternetOutBound` está toda la política por defecto: **de fuera
hacia dentro, cerrado; de dentro hacia fuera, abierto.**

Después se asocia el NSG a la subred de delante:

```bash
az network vnet subnet update --resource-group "$GRUPO" --vnet-name "$VNET" \
    --name snet-web --network-security-group "$NSG" --output table
```

**Coste hasta aquí: 0 €.** VNet, subredes y NSG no se facturan.

## Paso 3 — La VM de prueba (aquí empieza a facturar)

```bash
az vm create --resource-group "$GRUPO" --name "$VM" \
    --image Ubuntu2204 --size Standard_B1s \
    --vnet-name "$VNET" --subnet snet-web \
    --nsg-rule NONE \
    --admin-username azureuser --generate-ssh-keys --output table

az network nsg list --resource-group "$GRUPO" --output table
IP=$(az vm show -d -g "$GRUPO" -n "$VM" --query publicIps -o tsv)
```

- `--nsg-rule NONE` impide que Azure abra el SSH por su cuenta. Sin él, entrarías a la primera y
  el lab no enseñaría nada.
- **Salida esperada de `nsg list`:** solo `nsg-web`. Si apareciera un segundo NSG en la tarjeta de
  red, tendría que dejar pasar el tráfico **también**: con el tráfico entrante se evalúa primero el
  NSG de la subred y después el de la NIC, y si cualquiera de los dos deniega, el paquete se
  descarta.
- Los alias de imagen (`Ubuntu2204`) cambian con las versiones de la CLI. Se comprueban antes con
  `az vm image list --output table`.

## Paso 4 — El portazo, y abrir la puerta solo a mí

```bash
ssh -o ConnectTimeout=10 azureuser@"$IP"
```

**Salida esperada:** no hay "connection refused". La conexión **se queda colgada hasta el
timeout**. La regla `DenyAllInBound` descarta el paquete en silencio, y para quien está fuera la
máquina no existe. Es deliberado: contestar "rechazado" confirmaría que ahí hay algo.

```bash
MI_IP=$(curl -s https://api.ipify.org)
az network nsg rule create --resource-group "$GRUPO" --nsg-name "$NSG" \
    --name permitir-ssh-desde-mi-casa --priority 100 \
    --direction Inbound --access Allow --protocol Tcp \
    --source-address-prefixes "$MI_IP" --destination-port-ranges 22 --output table

ssh azureuser@"$IP"
```

**Salida esperada:** entra. El origen se limita a mi IP y no a `*`: abrir el 22 a todo internet es
lo que hace que haya bots escaneando ese puerto en toda Azure a todas horas.

## Paso 5 — La prioridad manda sobre la especificidad

```bash
az network nsg rule create --resource-group "$GRUPO" --nsg-name "$NSG" \
    --name bloquear-ssh-prueba --priority 90 \
    --direction Inbound --access Deny --protocol Tcp \
    --source-address-prefixes '*' --destination-port-ranges 22 --output table

ssh -o ConnectTimeout=10 azureuser@"$IP"
```

**Salida esperada:** vuelve el timeout, aunque el permiso de la 100 sigue ahí y es más específico
(una IP concreta frente a `*`). La 90 se evalúa antes y, según la documentación, *"once traffic
matches a rule, processing stops"*. **Solo cuenta el número.**

```bash
az network nsg rule delete -g "$GRUPO" --nsg-name "$NSG" --name bloquear-ssh-prueba
ssh azureuser@"$IP"   # vuelve a entrar
```

## Paso 6 — Los recursos huérfanos

```bash
az vm delete --resource-group "$GRUPO" --name "$VM" --yes
az resource list --resource-group "$GRUPO" --output table
```

**Salida esperada:** la VM ya no está, pero **siguen la tarjeta de red y la IP pública**, además de
la VNet y el NSG. La documentación lo dice así: *"By default, disks, NICs, and Public IPs associated
with a VM are persisted when the VM is deleted."* La IP pública sigue facturando sin una VM a la
que servir.

## Paso 7 — Borrar

```bash
./borrar-lab.sh
# o a mano:
az group delete --name "$GRUPO" --yes --no-wait
az group list --output table
```

**Salida esperada:** `rg-lab04-redes` desaparece de la lista. Borrar el grupo entero es la única
limpieza fiable: se lleva por delante los huérfanos del paso 6.

## Lo que hay que llevarse

```
prioridad baja = manda       ·  a la primera regla que encaja, se para
entrante cerrado por defecto ·  saliente abierto por defecto
subred Y NIC: los dos NSG tienen que dejar pasar
un NSG que deniega no contesta: timeout, no "rechazado"
az vm delete NO borra la NIC ni la IP pública → borrar por grupo
```

## Qué queda pendiente a propósito

- **Peering entre VNets**, VPN y ExpressRoute: conectar redes entre sí es otro tema.
- **Balanceadores y Application Gateway**: repartir tráfico no es filtrarlo.
- **Service tags y grupos de seguridad de aplicación**: la forma elegante de escribir el origen de
  una regla sin poner IPs a mano.
- **Network Watcher** (`ip-flow-verify`), que dice qué regla concreta bloqueó un paquete.
- **Endpoints privados** hacia el Storage Account del lab 01.

## Fuentes

- [Network security groups: visión general](https://learn.microsoft.com/en-us/azure/virtual-network/network-security-groups-overview): reglas, prioridad y las seis por defecto.
- [FAQ de redes virtuales](https://learn.microsoft.com/en-us/azure/virtual-network/virtual-networks-faq): las cinco direcciones reservadas.
- [Referencia de `az network nsg rule`](https://learn.microsoft.com/en-us/cli/azure/network/nsg/rule)
- [Qué se borra al borrar una VM](https://learn.microsoft.com/en-us/azure/virtual-machines/delete)