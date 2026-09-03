# ─────────────── ETAPA 1: BUILD (el taller) ───────────────
# Partimos del SDK porque aquí SÍ necesitamos compilar.
# La etapa se llama "build" para poder referirnos a ella más abajo.
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build

WORKDIR /app

# Traemos el código fuente
COPY . .

# Compilamos en Release y dejamos el publicado en /app/out
RUN dotnet publish -c Release -o /app/out


# ─────────────── ETAPA 2: RUNTIME (el producto final) ───────────────
# Empezamos DE CERO desde una imagen que solo trae el runtime de ASP.NET.
# Todo lo de la etapa "build" se queda atrás salvo lo que copiemos a mano.
FROM mcr.microsoft.com/dotnet/aspnet:8.0

WORKDIR /app

# El puente entre etapas: solo la carpeta publicada cruza
COPY --from=build /app/out .

ENV ASPNETCORE_URLS=http://+:8080

# Ojo: la ruta ya NO es out/DockerLab.dll, porque hemos copiado
# el CONTENIDO de /app/out directamente a /app
ENTRYPOINT ["dotnet", "DockerLab.dll"]