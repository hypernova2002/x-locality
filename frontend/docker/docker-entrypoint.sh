#!/bin/sh
# Runs via nginx's own /docker-entrypoint.d/ hook mechanism, before nginx
# starts - generates config.js from the API_BASE_URL env var so the API
# URL is set at container start, not baked into the build.
set -eu

: "${API_BASE_URL:=}"

envsubst '${API_BASE_URL}' \
  < /etc/nginx/templates/config.template.js \
  > /usr/share/nginx/html/config.js
