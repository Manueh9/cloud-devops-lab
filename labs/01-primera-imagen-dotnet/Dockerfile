# De qué partimos: una imagen que ya trae el SDK de .NET instalado
FROM mcr.microsoft.com/dotnet/sdk:8.0

# Carpeta de trabajo dentro del contenedor (se crea si no existe)
WORKDIR /app

# Copia todo lo de tu carpeta actual al /app del contenedor
COPY . .

# Compila en modo Release y deja el resultado en /app/out
RUN dotnet publish -c Release -o out

# La API escuchará en el 8080 dentro del contenedor
ENV ASPNETCORE_URLS=http://+:8080

# Qué se ejecuta cuando arranca el contenedor
ENTRYPOINT ["dotnet", "out/DockerLab.dll"]
