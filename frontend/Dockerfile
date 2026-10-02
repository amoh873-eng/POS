# syntax=docker/dockerfile:1
# POS Web — Flutter Web release build served by nginx (SPA + PWA + RTL aware).
# PHASE 32: separate web container; API traffic is reverse-proxied by nginx to pos-api.
# Context: ./frontend

# Pinned to the newest published stable image tag on ghcr (3.44.0 as of PHASE 32B);
# matches the 'stable' channel used by the GitHub Actions frontend job.
FROM ghcr.io/cirruslabs/flutter:3.44.0 AS build
WORKDIR /app

# Restore first for layer caching
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get
COPY . .
# Same-origin architecture: API_BASE_URL left empty on purpose (AppConfig uses
# Uri.base.origin at runtime, so /api /uploads /health are proxied by nginx).
RUN flutter build web --release

FROM nginx:1.27-alpine AS runtime
# SPA fallback + API/uploads reverse proxy (see nginx.conf)
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/build/web /usr/share/nginx/html

EXPOSE 80

HEALTHCHECK --interval=15s --timeout=3s --start-period=20s --retries=5 \
    CMD wget -q -O /dev/null http://127.0.0.1/ || exit 1

CMD ["nginx", "-g", "daemon off;"]