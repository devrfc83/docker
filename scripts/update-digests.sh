#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
COMPOSE_FILE="${ROOT_DIR}/docker-compose.yml"
OSM_DOCKERFILE="${ROOT_DIR}/osm/Dockerfile"
MODE="${1:-update}"

require_cmd() {
    if ! command -v "$1" >/dev/null 2>&1; then
        echo "Error: comando requerido no encontrado: $1" >&2
        exit 1
    fi
}

skopeo_auth_args() {
    local authfile="${DOCKER_CONFIG:-$HOME/.docker}/config.json"
    if [[ -f "$authfile" ]]; then
        printf '%s\n' --authfile "$authfile"
    fi
}

get_digest_ref() {
    local image_ref="$1"
    local name digest
    # shellcheck disable=SC2046
    name="$(skopeo inspect $(skopeo_auth_args) "docker://${image_ref}" | jq -r '.Name')"
    # shellcheck disable=SC2046
    digest="$(skopeo inspect $(skopeo_auth_args) "docker://${image_ref}" | jq -r '.Digest')"
    if [[ -z "$name" || -z "$digest" || "$digest" == "null" ]]; then
        return 1
    fi
    printf '%s@%s\n' "$name" "$digest"
}

replace_line() {
    local file="$1"
    local pattern="$2"
    local replacement="$3"
    sed -i "s#${pattern}#${replacement}#g" "$file"
}

assert_contains() {
    local file="$1"
    local expected="$2"
    if ! grep -Fq "$expected" "$file"; then
        echo "Desactualizado: $file"
        echo "Esperado: $expected"
        return 1
    fi
    echo "OK: $file contiene $expected"
}

require_cmd skopeo
require_cmd jq
require_cmd sed
require_cmd grep

MINIO_REF=""
if ref="$(get_digest_ref "docker.io/minio/minio:RELEASE.2025-09-07T16-13-09Z" 2>/dev/null)" && [[ "$ref" == *@sha256:* ]]; then
    MINIO_REF="$ref"
fi

OSM_REF=""
if ref="$(get_digest_ref "docker.io/overv/openstreetmap-tile-server:v2.1.0" 2>/dev/null)" && [[ "$ref" == *@sha256:* ]]; then
    OSM_REF="$ref"
fi

KEYCLOAK_REF=""
if ref="$(get_digest_ref "dhi.io/keycloak:26.6.2-dev" 2>/dev/null)" && [[ "$ref" == *@sha256:* ]]; then
    KEYCLOAK_REF="$ref"
fi

POSTGRES_REF=""
if ref="$(get_digest_ref "docker.io/postgis/postgis:18-3.6" 2>/dev/null)" && [[ "$ref" == *@sha256:* ]]; then
    POSTGRES_REF="$ref"
fi

check_keycloak_image() {
    if [[ -n "$KEYCLOAK_REF" ]]; then
        assert_contains "$COMPOSE_FILE" "image: ${KEYCLOAK_REF}"
        return
    fi
    if grep -Eq 'image: dhi\.io/keycloak@sha256:[a-f0-9]{64}' "$COMPOSE_FILE"; then
        echo "OK: $COMPOSE_FILE contiene imagen DHI keycloak (digest fijo; sin auth a dhi.io)"
        return 0
    fi
    echo "Desactualizado: $COMPOSE_FILE (falta dhi.io/keycloak@sha256:...)"
    return 1
}

check_postgres_image() {
    if [[ -n "$POSTGRES_REF" ]]; then
        assert_contains "$COMPOSE_FILE" "image: ${POSTGRES_REF}"
        return
    fi
    if grep -Eq 'image: docker\.io/postgis/postgis@sha256:[a-f0-9]{64}' "$COMPOSE_FILE"; then
        echo "OK: $COMPOSE_FILE contiene imagen postgis/postgis (digest fijo)"
        return 0
    fi
    echo "Desactualizado: $COMPOSE_FILE (falta docker.io/postgis/postgis@sha256:...)"
    return 1
}

if [[ "$MODE" == "check" ]]; then
    echo "Verificando referencias inmutables de imagen..."
    failures=0

    if [[ -n "$MINIO_REF" ]]; then
        assert_contains "$COMPOSE_FILE" "image: ${MINIO_REF}" || failures=1
    elif grep -Eq 'image: docker\.io/minio/minio@sha256:[a-f0-9]{64}' "$COMPOSE_FILE"; then
        echo "OK: $COMPOSE_FILE contiene minio (digest fijo)"
    else
        echo "Desactualizado: minio"; failures=1
    fi

    check_keycloak_image || failures=1
    check_postgres_image || failures=1

    if [[ -n "$OSM_REF" ]]; then
        assert_contains "$OSM_DOCKERFILE" "FROM ${OSM_REF}" || failures=1
    elif grep -Eq 'FROM docker\.io/overv/openstreetmap-tile-server@sha256:[a-f0-9]{64}' "$OSM_DOCKERFILE"; then
        echo "OK: $OSM_DOCKERFILE contiene OSM (digest fijo)"
    else
        echo "Desactualizado: OSM"; failures=1
    fi

    if [[ "$failures" -ne 0 ]]; then
        echo "Hay digests desactualizados. Ejecuta: make update-digests"
        exit 1
    fi

    echo "Todo al dia."
    exit 0
fi

echo "Actualizando referencias inmutables de imagen..."

if [[ -z "$MINIO_REF" ]]; then
    MINIO_REF="$(get_digest_ref "docker.io/minio/minio:RELEASE.2025-09-07T16-13-09Z")"
fi
if [[ -z "$OSM_REF" ]]; then
    OSM_REF="$(get_digest_ref "docker.io/overv/openstreetmap-tile-server:v2.1.0")"
fi

if [[ -z "$KEYCLOAK_REF" ]]; then
    KEYCLOAK_REF="$(get_digest_ref "dhi.io/keycloak:26.6.2-dev")" || {
        echo "Error: no se pudo resolver dhi.io/keycloak:26.6.2-dev. Ejecuta: docker login dhi.io" >&2
        exit 1
    }
fi

if [[ -z "$POSTGRES_REF" ]]; then
    POSTGRES_REF="$(get_digest_ref "docker.io/postgis/postgis:18-3.6")" || {
        echo "Error: no se pudo resolver docker.io/postgis/postgis:18-3.6" >&2
        exit 1
    }
fi

for ref in "$MINIO_REF" "$KEYCLOAK_REF" "$POSTGRES_REF" "$OSM_REF"; do
    if [[ ! "$ref" =~ @sha256:[a-f0-9]{64}$ ]]; then
        echo "Error: referencia de imagen invalida: ${ref:-<vacia>}" >&2
        exit 1
    fi
done

replace_line "$COMPOSE_FILE" \
    "image: docker.io/minio/minio@sha256:[a-f0-9]\\{64\\}" \
    "image: ${MINIO_REF}"

replace_line "$COMPOSE_FILE" \
    "image: dhi.io/keycloak@sha256:[a-f0-9]\\{64\\}" \
    "image: ${KEYCLOAK_REF}"

replace_line "$COMPOSE_FILE" \
    "image: docker.io/postgis/postgis@sha256:[a-f0-9]\\{64\\}" \
    "image: ${POSTGRES_REF}"

replace_line "$OSM_DOCKERFILE" \
    "FROM docker.io/overv/openstreetmap-tile-server@sha256:[a-f0-9]\\{64\\}" \
    "FROM ${OSM_REF}"

echo "Listo. Archivos actualizados:"
echo "- ${COMPOSE_FILE}"
echo "- ${OSM_DOCKERFILE}"
