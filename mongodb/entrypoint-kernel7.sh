#!/bin/sh
# Workaround kernel 6.19+ (incompatibilidad TCMalloc/RSEQ en MongoDB 8.x).
# - GLIBC_TUNABLES=glibc.pthread.rseq=1 evita cierres por SIGSEGV en runtime.
# - El entrypoint upstream bloquea el arranque en kernel reciente; lo omitimos
#   manteniendo el resto del flujo (init de credenciales, etc.).
set -eu

export GLIBC_TUNABLES=glibc.pthread.rseq=1

EP_ORIG=/usr/local/bin/docker-entrypoint.py
EP_PATCHED=/tmp/docker-entrypoint-patched.py
cp "$EP_ORIG" "$EP_PATCHED"
sed -i '/def enforce_kernel_compatibility/,/^def / s/sys\.exit(1)/return/' "$EP_PATCHED"

exec python3 "$EP_PATCHED" "$@"
