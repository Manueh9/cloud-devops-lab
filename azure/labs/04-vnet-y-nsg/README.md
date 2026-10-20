# Lab 04 · VNet y NSG: quién puede entrar

> Anterior: [lab 03 · La API .NET en App Service](../03-app-service/)
> Teoría: [apuntes/04-redes-vnet-y-nsg.md](../../apuntes/04-redes-vnet-y-nsg.md)

## Objetivo

Montar una red privada en Azure con dos subredes, poner un grupo de seguridad de red en la subred
de delante y demostrar con una máquina de prueba que **el acceso lo decide la regla, no la
aplicación**: el mismo servidor, levantado todo el rato, es inalcanzable o alcanzable según lo que
diga el NSG.

Y, de paso, ver qué recursos sobreviven a `az vm delete` — que es la razón por la que en esta
carpeta todo se borra por grupo.

## Antes de empezar

- Azure CLI con sesión iniciada (ver [lab 02](../02-az-cli/)).
- Región: `francecentral` (West Europe devolvía `RequestDisallowedByAzure` por saturación).
- Crédito disponible: la red es gratis, pero la VM de prueba **factura por hora**.

## Lo que se monta

```
VNet  vnet-lab04   10.10.0.0/16
├── snet-web     10.10.1.0/24   ← con el NSG nsg-web asociado
│   └── vm-web   (Standard_B1s, Ubuntu, sin NSG en la tarjeta de red)
└── snet-datos   10.10.2.0/24   ← vacía, para ver que una subred es un recurso aparte
```

## Los pasos

1. Crear el grupo, la VNet y las dos subredes.
2. Crear el NSG y **listar sus reglas por defecto** con `--include-default`. Son seis y no se
   pueden borrar.
3. Asociar el NSG a `snet-web`.
4. Crear la VM con `--nsg-rule NONE`, para que Azure no abra el SSH por su cuenta.
5. Comprobar cuántos NSG existen: el de la subred y, si Azure creó otro, el de la tarjeta de red.
   **Los dos tienen que dejar pasar el tráfico entrante.**
6. Intentar SSH → no llega (la regla `DenyAllInBound` de la 65500).
7. Abrir el 22 **solo para la IP propia** en la prioridad 100 → entra.
8. Meter una denegación en la prioridad **90** → deja de entrar, aunque el permiso siga ahí.
9. Quitar la denegación, levantar un servidor en el 8080 y repetir el ciclo cerrado/abierto.
10. Borrar solo la VM y listar el grupo: la NIC y la IP pública siguen vivas.
11. `az group delete`.

## Resultado real

```
$ az network vnet subnet list -g rg-lab04-redes --vnet-name vnet-lab04 -o table
<<PEGA AQUÍ>>

$ az network nsg rule list -g rg-lab04-redes --nsg-name nsg-web --include-default -o table
<<PEGA AQUÍ las seis reglas por defecto>>

$ az network nsg list -g rg-lab04-redes -o table
<<PENDIENTE: jueves — ¿uno o dos NSG?>>

$ ssh -o ConnectTimeout=10 azureuser@<ip>      # sin regla
<<PENDIENTE: jueves>>

$ ssh azureuser@<ip>                            # con la regla de la prioridad 100
<<PENDIENTE: jueves>>

$ ssh -o ConnectTimeout=10 azureuser@<ip>      # con la denegación en la prioridad 90
<<PENDIENTE: jueves>>

$ az resource list -g rg-lab04-redes -o table   # después de az vm delete
<<PENDIENTE: jueves — la NIC y la IP pública siguen ahí>>
```

| Dato | Valor |
|---|---|
| Rango de la VNet | `<<PEGA AQUÍ>>` |
| Alias de imagen usado | `<<PENDIENTE: jueves>>` |
| Precio estimado que mostró Azure para la B1s | `<<PENDIENTE: jueves>>` |
| Coste real en Cost analysis al terminar | `<<PENDIENTE: jueves>>` |
| ¿Azure creó un segundo NSG en la NIC? | `<<PENDIENTE: jueves>>` |

## Errores con los que me topé

<<PEGA AQUÍ los reales. Candidatos:>>
- <<Las reglas de la subred no surtían efecto porque había un segundo NSG en la tarjeta de red.>>
- <<El alias de imagen del ejemplo no existía; hubo que mirar `az vm image list`.>>
- <<El SSH no daba error, se quedaba colgado: un NSG que deniega descarta en silencio.>>

## Qué queda pendiente a propósito

- **Peering entre VNets**, VPN y ExpressRoute: conectar redes entre sí es otro tema.
- **Balanceadores y Application Gateway**: repartir tráfico no es filtrarlo.
- **Service tags y grupos de seguridad de aplicación**: la forma elegante de escribir el origen de
  una regla sin poner IPs a mano. Se queda para la segunda vuelta de redes.
- **Network Watcher** (`ip-flow-verify`), que dice qué regla concreta bloqueó un paquete. Es la
  herramienta de diagnóstico del tema y merece su propia sesión.
- **Endpoints privados** hacia el Storage Account del lab 01: es la unión natural entre el lab 01 y
  este, y es el siguiente paso lógico de redes.

## La limpieza

```bash
./borrar-lab.sh
# o, a mano:
az group delete --name rg-lab04-redes --yes --no-wait
az group list --output table
```

Borrar la VM **no basta**: su tarjeta de red y su IP pública sobreviven, y la IP pública factura.