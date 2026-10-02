# syntax=docker/dockerfile:1
# POS Web — Flutter Web release build served by nginx (SPA + PWA + RTL aware).
# PHASE 32: separate web container; API traffic is reverse-proxied by nginx to pos-api.
# Context: ./frontend

FROM ghcr.io/cirruslabs/flutter:3.47.1-stable AS build
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

HEALTHCHECK --interval=15s --timeout=3s --start-period=10s --retries=5 \
    CMD wget -q -O /dev/null http://localhost/ || exit 1

CMD ["nginx", "-g", "daemon off;"]