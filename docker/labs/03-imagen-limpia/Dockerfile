# ─────────────── ETAPA 1: BUILD ───────────────
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build

WORKDIR /src

# Gracias al .dockerignore de la raíz del contexto, este "COPY . ."
# ya no arrastra bin/, obj/ ni .vs/
COPY . .

RUN dotnet publish -c Release -o /app/out


# ─────────────── ETAPA 2: RUNTIME ───────────────
FROM mcr.microsoft.com/dotnet/aspnet:8.0

WORKDIR /app

COPY --from=build /app/out .

# Valor POR DEFECTO. Se puede pisar al arrancar con:  docker run -e ASPNETCORE_ENVIRONMENT=Development
ENV ASPNETCORE_ENVIRONMENT=Production
ENV ASPNETCORE_URLS=http://+:8080

# Documenta que el proceso escucha ahí dentro. No publica nada por sí solo:
# publicar sigue siendo cosa del -p del docker run.
EXPOSE 8080

# El usuario "app" (UID 1654) ya viene creado en las imágenes oficiales de .NET 8.
# A partir de esta línea, todo lo que siga se ejecuta sin privilegios de root.
# Va al final, después de copiar: si lo pones antes, los COPY pueden fallar por permisos.
USER app

ENTRYPOINT ["dotnet", "DockerLab.dll"]