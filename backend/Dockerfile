# syntax=docker/dockerfile:1
# PosCloud.Api — production multi-stage build (.NET 10)
# Context: ./backend (so sibling projects Domain/Application/Infrastructure are available)
# PHASE 32: .NET 10 SDK/runtime, non-root app user, /app/uploads volume root for images.
# No secrets embedded — all runtime config via environment variables.

FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src

# Copy csproj and restore first for better layer caching
COPY src/PosCloud.Domain/PosCloud.Domain.csproj src/PosCloud.Domain/
COPY src/PosCloud.Application/PosCloud.Application.csproj src/PosCloud.Application/
COPY src/PosCloud.Infrastructure/PosCloud.Infrastructure.csproj src/PosCloud.Infrastructure/
COPY src/PosCloud.Api/PosCloud.Api.csproj src/PosCloud.Api/

RUN dotnet restore src/PosCloud.Api/PosCloud.Api.csproj

# Copy remaining source and publish (full restore to bypass solution-layout quirks)
COPY . .
WORKDIR /src/src/PosCloud.Api
RUN dotnet publish -c Release -o /app/publish /p:UseAppHost=false

FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS runtime
WORKDIR /app

# curl for Docker healthcheck
RUN apt-get update && apt-get install -y --no-install-recommends curl \
    && rm -rf /var/lib/apt/lists/*

COPY --from=build /app/publish .

# Unified uploads volume (persistent named volume mounted at /app/uploads by compose).
# Named volumes are initialized from the image contents, so pre-creating + chown'ing
# means the runtime app user (uid 1654) owns the volume on first mount.
RUN mkdir -p /app/uploads/products \
    && chown -R app:app /app/uploads

# Do not run as root (PHASE 32 — app user).
USER app

ENV ASPNETCORE_URLS=http://+:8080
EXPOSE 8080

HEALTHCHECK --interval=15s --timeout=3s --start-period=25s --retries=5 \
    CMD curl -fsS http://localhost:8080/health || exit 1

ENTRYPOINT ["dotnet", "PosCloud.Api.dll"]
