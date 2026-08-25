# syntax=docker/dockerfile:1
# PosCloud.Api — production multi-stage build (.NET 8)
# Context: ./backend (so sibling projects Domain/Application/Infrastructure are available)
# No secrets embedded — all runtime config via environment variables (ConnectionStrings__Default, Jwt__Key, etc.)

FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

# Copy csproj and restore first for better layer caching
COPY src/PosCloud.Domain/PosCloud.Domain.csproj src/PosCloud.Domain/
COPY src/PosCloud.Application/PosCloud.Application.csproj src/PosCloud.Application/
COPY src/PosCloud.Infrastructure/PosCloud.Infrastructure.csproj src/PosCloud.Infrastructure/
COPY src/PosCloud.Api/PosCloud.Api.csproj src/PosCloud.Api/

RUN dotnet restore src/PosCloud.Api/PosCloud.Api.csproj

# Copy remaining source and publish (full restore, not --no-restore, to avoid stale layer with PosCloud.sln outside context)
COPY . .
WORKDIR /src/src/PosCloud.Api
RUN dotnet publish -c Release -o /app/publish /p:UseAppHost=false

FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS runtime
WORKDIR /app

# Install curl for Docker healthcheck (api: curl -f http://localhost:8080/health)
RUN apt-get update && apt-get install -y --no-install-recommends curl && rm -rf /var/lib/apt/lists/*

# Non-root is optional — keep root for now to avoid permission issues with wwwroot; can switch to app user later
COPY --from=build /app/publish .

EXPOSE 8080
ENV ASPNETCORE_URLS=http://+:8080
# Do not set ConnectionStrings, Jwt__Key, or any secret here — injected via docker-compose environment

ENTRYPOINT ["dotnet", "PosCloud.Api.dll"]
