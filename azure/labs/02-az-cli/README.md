# Lab 02 · Los mismos recursos, desde la terminal

> Anterior: [lab 01 · Primer grupo de recursos](../01-primer-grupo-de-recursos/)
> Teoría: [apuntes/02-azure-cli.md](../../apuntes/02-azure-cli.md)

## Objetivo

Repetir el lab 01 —grupo, storage, contenedor y blob— sin abrir el navegador, y dejarlo escrito en
dos scripts (`crear-lab.sh` y `borrar-lab.sh`) que se pueden ejecutar tantas veces como haga falta.
La diferencia no es la comodidad: es que lo escrito se repite y se revisa, y lo hecho a clics no.
Es el primer paso hacia la infraestructura como código.

## Antes de empezar

```bash
brew update && brew install azure-cli
az login --tenant <TENANT_ID>     # --tenant obliga a completar el MFA en el navegador
az account show --output table
```

## Pasos

1. Ejecutar los comandos uno a uno para ver qué devuelve cada uno.
2. Comprobar en vivo el concepto de RBAC: con tu identidad, crear el contenedor funciona pero subir
   el blob falla, hasta asignarte el rol de datos.
3. Borrar el grupo y reconstruirlo **desde `crear-lab.sh`**.
4. Borrar con `borrar-lab.sh` y verificar con `az group list` que no queda nada.

```bash
chmod +x crear-lab.sh borrar-lab.sh
./crear-lab.sh
./borrar-lab.sh
```

## Resultado real

```
$ az account show --output table
EnvironmentName    IsDefault    Name                  State    TenantId
-----------------  -----------  --------------------  -------  ------------------------------------
AzureCloud         True         Azure subscription 1  Enabled  aa046934-...

$ ./crear-lab.sh
==> Grupo:   rg-lab02-azcli (francecentral)
==> Storage: stlab0271722913
... (crea el grupo, el storage StorageV2, asigna el rol, espera la propagacion,
     crea el contenedor, sube prueba.txt y lo lista)
Finished[###...###]  100.0000%
prueba.txt  BlockBlob  Hot  70  text/plain
LISTO. Para borrarlo todo:  ./borrar-lab.sh

$ ./borrar-lab.sh
$ az group list --output table
<<PEGA AQUI la salida: rg-lab02-azcli ya no debe aparecer>>
```

## Errores con los que me topé

1. **MFA al entrar.** `az login` a secas devolvió `AADSTS50076 ... must use multi-factor
   authentication` y `No subscriptions found`. Se arregló con `az login --tenant <id>`, que fuerza
   el segundo factor en el navegador.
2. **El permiso de datos.** Con mi identidad pude crear el contenedor (gestión) pero NO subir el
   blob (datos): `You do not have the required permissions ... "Storage Blob Data Contributor"`. Se
   resolvió asignándome ese rol, acotado solo a este storage.

## Lo que aprendí que no esperaba

La frontera gestión/datos no está donde pensaba. Ser Owner te deja crear y borrar la cuenta y los
contenedores (Actions), pero el contenido de los blobs (DataActions) es otra categoría de permiso
que Owner no trae de serie. Administrar un recurso y leer sus datos son cosas distintas a propósito.

## Qué queda pendiente a propósito

- **RBAC en serio** (roles, ámbitos, principales, identidades gestionadas): tiene su propio bloque.
  Aquí solo me asigné el rol mínimo para que el lab corra.
- **Las claves de la cuenta** (`--auth-mode key`) no se usan: se trabaja con la identidad porque una
  clave en un script acaba en el repo.
- **Endurecer el TLS**: la CLI creó el storage con `MinimumTlsVersion = TLS1_0`; lo razonable en
  producción es TLS1_2. Es una decisión de seguridad para otro día.
- **Describir esto declarativamente** (Terraform) llega en la Fase 2: un script `az` dice *los
  pasos*; Terraform diría *el resultado*.