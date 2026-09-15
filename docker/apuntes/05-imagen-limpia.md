# 05 · Imagen limpia: `.dockerignore`, variables de entorno y usuario no-root

> Anterior: [04 · Multi-stage builds](04-multi-stage.md) · Siguiente: *(pendiente)*
> Lab que lo acompaña: [labs/03-imagen-limpia](../labs/03-imagen-limpia/)

En el apunte anterior conseguimos una imagen pequeña. Pequeña, sin embargo, no es lo mismo
que buena. A una imagen que va a ir a producción le faltan todavía tres cosas: no arrastrar
basura, poder configurarse sin reconstruirla, y no ejecutarse como root. Este apunte va de
esas tres.

## 1. El contexto de build y el `.dockerignore`

Cuando ejecutas `docker build ... <ruta>`, esa ruta final es el **contexto de build**. Antes
de ejecutar la primera instrucción del Dockerfile, Docker empaqueta esa carpeta **entera** y
se la envía al motor de construcción. Da igual que tu Dockerfile solo vaya a copiar tres
ficheros: el viaje se paga completo.

Eso significa que si en la carpeta hay resultados de compilación (`bin/`, `obj/`), carpetas
de IDE (`.vs/`) o dependencias descargadas, todo eso se transfiere para nada. Cuesta tiempo
en cada build y, como veremos en el apunte siguiente, estropea el aprovechamiento de la
caché.

El `.dockerignore` es la lista de lo que **no** se empaqueta. Su sintaxis se parece a la del
`.gitignore`, pero son cosas distintas y no se conocen entre sí:

| | `.gitignore` | `.dockerignore` |
|---|---|---|
| Dónde vive | Raíz del repositorio | **Raíz del contexto de build** |
| Qué evita | Que un fichero se suba al repositorio | Que un fichero viaje al build |

**El detalle que más confunde:** si separas la receta del contexto con `-f`, como hacemos en
este repositorio, Docker sigue buscando el `.dockerignore` **en la raíz del contexto**, no
junto al Dockerfile. En este repositorio, por tanto, vive en `app/DockerLab/.dockerignore`.

> **Analogía.** El contexto de build es lo que subes al camión de mudanzas; el Dockerfile es
> lo que colocas al llegar. Sin `.dockerignore` estás subiendo al camión el cubo de la basura
> para después no usarlo. El viaje lo pagas igual.

Un efecto curioso y honesto de contar: como el `.gitignore` de este repositorio ya excluye
`bin/` y `obj/`, quien clone el repositorio de cero **no tiene esas carpetas** y verá una
mejora de cero al añadir el `.dockerignore`. La mejora se ve en la máquina de quien compila
en local, donde esas carpetas sí existen. No es un fallo del ejercicio: es cómo funciona.

## 2. Configuración: `ENV` frente a `-e`

Una imagen debe ser una sola y servir para varios entornos. Lo que cambia entre ellos (nivel
de log, cadena de conexión, URLs de servicios) no puede estar cocido dentro de la imagen.

- **`ENV` en el Dockerfile** fija el valor **por defecto**, en tiempo de construcción.
- **`-e` en `docker run`** fija el valor **de este contenedor**, en tiempo de ejecución, y
  pisa al anterior.

```dockerfile
ENV ASPNETCORE_ENVIRONMENT=Production
```

```bash
docker run -e ASPNETCORE_ENVIRONMENT=Development ...
```

> **Analogía (C#).** `ENV` es el valor por defecto de un parámetro,
> `void Run(string entorno = "Production")`. El `-e` es el argumento real de la llamada.
> Si vienes de ASP.NET esto ya lo has vivido: `appsettings.json` hace de `ENV` y las
> variables de entorno del sistema hacen de `-e`. El orden de precedencia del
> `ConfigurationBuilder` es exactamente ese.

**Nunca un secreto en un `ENV`.** Queda escrito dentro de la imagen y cualquiera con acceso
a ella lo lee con `docker history`. Los secretos necesitan otra solución (un gestor de
secretos), que queda fuera de este apunte.

## 3. Usuario no-root

Por defecto, el proceso de dentro del contenedor corre como `root`. No es el root de la
máquina anfitriona, pero es el usuario más privilegiado dentro del contenedor: escribe donde
quiera, instala lo que quiera y, si alguien consigue escaparse del contenedor, empieza con
la mejor mano posible.

Las imágenes oficiales de .NET 8 **ya traen creado** un usuario sin privilegios llamado
`app`, con UID `1654`. Solo hay que activarlo:

```dockerfile
USER app
```

Se pone **después** de los `COPY`. Si se pone antes, las copias pueden fallar por permisos.

### Por qué el puerto es 8080 y no 80

Esto conecta con algo que arrastrábamos desde el primer lab sin explicarlo. En Linux, **los
puertos por debajo de 1024 solo los puede abrir el usuario root**. Como Microsoft quiso que
sus imágenes de .NET 8 fuesen no-root por defecto, tuvo que mover el puerto por defecto del
80 al 8080.

De ahí que el `ENV ASPNETCORE_URLS=http://+:8080` de los labs anteriores no fuese un número
arbitrario. Y de ahí también la consecuencia práctica: **si devuelves la aplicación al
puerto 80, ya no puedes ejecutarla como no-root.** Las dos decisiones son la misma decisión.

Fuera, en el `docker run -p 8082:8080`, puedes publicar el puerto que quieras: el que manda
esa regla es el sistema anfitrión, no el contenedor.

## 4. `EXPOSE` no publica nada

`EXPOSE 8080` es **documentación**. Le dice a quien lea la imagen "el proceso de dentro
escucha en el 8080". No abre el puerto hacia fuera. Quien publica sigue siendo `-p` en el
`docker run`. Es un error muy común esperar que `EXPOSE` haga algo por sí solo.

## 5. Comprobaciones

```bash
docker exec <contenedor> whoami   # -> app
docker exec <contenedor> id       # -> uid=1654(app) ...
```

Si `whoami` devuelve `root`, la instrucción `USER` no está surtiendo efecto: revisa que esté
en la **última** etapa del Dockerfile y no en la de build.


---
## Para leer más

- [Docker Build context](https://docs.docker.com/build/concepts/context/) (doc oficial)

---

⬅️ Anterior: [04 · Chuleta de comandos](04-multi-stage.md)
➡️ Siguiente: *pendiente*
🧪 Lab que aplica este apunte: [03 · Imagen limpia](../labs/03-imagen-limpia/)