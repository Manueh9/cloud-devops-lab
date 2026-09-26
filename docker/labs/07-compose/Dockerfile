# ─────────────── ETAPA 1: BUILD ───────────────
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build

WORKDIR /src

# PASO 1 — solo el fichero de proyecto.
# Cambia poco (solo al añadir o quitar un paquete), asi que va arriba del todo.
COPY *.csproj ./

# PASO 2 — restaurar dependencias.
# Es el paso lento y el unico que toca la red. Al depender solo del .csproj,
# esta capa se reutiliza mientras no toques las dependencias.
RUN dotnet restore

# PASO 3 — ahora si, el resto del codigo.
# Cambia constantemente, asi que va lo mas abajo posible de la fila de domino.
COPY . .

# PASO 4 — publicar sin volver a restaurar: ya se hizo en el paso 2.
# Sin --no-restore, publish restaura otra vez y el truco entero no sirve de nada.
RUN dotnet publish -c Release -o /app/out --no-restore


# ─────────────── ETAPA 2: RUNTIME ───────────────
FROM mcr.microsoft.com/dotnet/aspnet:8.0

WORKDIR /app

COPY --from=build /app/out .

ENV ASPNETCORE_ENVIRONMENT=Production
ENV ASPNETCORE_URLS=http://+:8080

EXPOSE 8080

USER app

ENTRYPOINT ["dotnet", "DockerLab.dll"]
