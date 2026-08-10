FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS base
WORKDIR /app

FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /source

COPY ["global.json", "./"]
COPY ["Directory.Packages.props", "./"]
COPY ["src/main/Core/Core.csproj", "./Core/"]
COPY ["src/main/Infra.MongoDB/Infra.MongoDB.csproj", "./Infra.MongoDB/"]
COPY ["src/main/EntryPoint.WebApi/EntryPoint.WebApi.csproj", "./EntryPoint.WebApi/"]

RUN dotnet restore "./EntryPoint.WebApi/EntryPoint.WebApi.csproj" --no-cache

COPY ./src/main/Core/. ./Core/
COPY ./src/main/Infra.MongoDB/. ./Infra.MongoDB/
COPY ./src/main/EntryPoint.WebApi/. ./EntryPoint.WebApi/

FROM build AS publish
WORKDIR /source/EntryPoint.WebApi
RUN dotnet publish "EntryPoint.WebApi.csproj" -c Release --no-restore -o /app/publish

FROM base AS final
WORKDIR /app

ENV COMPlus_EnableDiagnostics=0 \
    ASPNETCORE_URLS=http://*:8000

COPY --from=publish --chown=app:app /app/publish .

EXPOSE 8000

USER app

HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
  CMD curl -f http://localhost:8000/health-check/live || exit 1

ENTRYPOINT ["dotnet", "EntryPoint.WebApi.dll"]
