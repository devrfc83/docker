# Entorno Docker

Stack de desarrollo local para aplicaciones web. Credenciales predecibles a proposito; **no usar en produccion**.

## Inicio rapido

Requisito previo: **rsyslog** en el host (una sola vez).

```bash
sudo cp rsyslog/docker.conf /etc/rsyslog.d/docker.conf
sudo mkdir -p /var/log/docker
sudo systemctl enable --now rsyslog
```

Luego:

```bash
cd "$HOME/Docker"   # o la ruta de tu clon
docker login dhi.io # solo para pull de Keycloak DHI
docker compose up -d
```

Levanta solo lo que necesites:

```bash
docker compose up -d postgresql valkey mail
```

Logs de contenedores: `tail -f /var/log/docker/postgresql.log`

## Puertos y credenciales

| Servicio | Puerto | Usuario | Contrasena | Notas |
|----------|--------|---------|------------|-------|
| keycloak | 20001 HTTP, 20002 HTTPS | `admin` | `admin` | Realm `dev` en `keycloak/realm.json` |
| mail | 25 SMTP, 20003 web | — | — | MailHog, sin auth |
| minio | 20004 API, 20005 consola | `administrator` | `administrator` | |
| osm | 20006 | — | — | Requiere PBF; ver [docs/osm-import.md](docs/osm-import.md) |
| grafana | 20007 | `admin` | `grafana` | |
| postgresql | 5432 | `postgres` | `postgres` | PostGIS 3.6; ver bases abajo |
| mariadb | 3306 | `root` | `root` | |
| mongodb | 27017 | `mongodb` | `mongodb` | `authSource=admin` |
| valkey | 6379 | `valkey` | `valkey` | Compatible Redis |
| memcached | 11211 | `memcached` | `memcached` | SASL `memcached@localhost` |

### Bases PostgreSQL

| Base | Usuario | Contrasena |
|------|---------|------------|
| `development` | `developer` | `developer` |
| `testing` | `tester` | `tester` |
| `auditing` | `auditor` | `auditor` |
| `pulse` | `pulse` | `pulse` |
| `keycloak` | `keycloak` | `keycloak` |

Todas incluyen PostGIS (plantilla `template_full_cl`, locale ICU `es-CL`). Los roles tienen SUPERUSER solo en local.

### Bases MariaDB

Mismos nombres de usuario/base que PostgreSQL (`developer`/`development`, etc.), sin `keycloak`.

### Keycloak (realm `dev`)

Usuarios de ejemplo: `dev-user`/`dev123`, `admin@example.org`/`password`. Cliente Laravel: `laravel-app`. Guia completa en [docs/laravel-keycloak.md](docs/laravel-keycloak.md).

## Imagenes

| Servicio | Imagen | Digest fijo |
|----------|--------|-------------|
| keycloak | `dhi.io/keycloak:26.6.2-dev` | Si |
| postgresql | `postgis/postgis:18-3.6` | Si |
| minio | `minio/minio:RELEASE.2025-09-07` | Si |
| osm | build local (`overv/openstreetmap-tile-server:v2.1.0`) | Si (base) |
| mail, memcached, valkey, mariadb, mongodb, grafana | tags versionados | No |

Actualizar digests: `make update-digests` (requiere `skopeo`, `jq` y `docker login dhi.io`).

## Memoria (~8 GB en el host)

| Servicio | Limite | Ajuste interno |
|----------|--------|----------------|
| keycloak | 512 MB | JVM `-Xmx384m` |
| postgresql | 384 MB | `shared_buffers=96MB` |
| mariadb | 384 MB | `innodb_buffer_pool_size=96M` |
| mongodb | 384 MB | WiredTiger 0,25 GB |
| osm | 768 MB | El mas pesado |
| minio | 256 MB | — |
| grafana | 256 MB | — |
| valkey | 192 MB | `maxmemory 128mb` |
| memcached | 96 MB | `-m 64` |
| mail | 64 MB | — |

Tope teorico con todo levantado: **3,2 GB** de contenedores. Quita del compose lo que no uses.

## Logging

Todos los contenedores envian stdout/stderr a **rsyslog** del host (`udp://127.0.0.1:514`). Un fichero por servicio en `/var/log/docker/<nombre>.log`.

Flujo: motor → consola del contenedor → driver `syslog` de Docker → rsyslog → fichero.

Sin rsyslog configurado los contenedores arrancan igual, pero los logs UDP se pierden.

## Estructura del repositorio

```text
docker-compose.yml      Stack principal
postgres/init/          Plantilla PostGIS + roles/bases
mariadb/init/           Usuarios y bases
keycloak/realm.json     Realm de desarrollo
rsyslog/docker.conf     Config para el host
scripts/update-digests.sh
docs/                   Guias extendidas
```

## Mantenimiento

```bash
docker compose pull && docker compose up -d   # version menor
make update-digests                           # refrescar @sha256
make check-digests                            # comprobar sin modificar
```

Subir **version mayor** de una base de datos: [docs/upgrading-databases.md](docs/upgrading-databases.md).

## Mas documentacion

- [Laravel + Keycloak](docs/laravel-keycloak.md)
- [Importacion OSM](docs/osm-import.md)
- [Upgrade de bases de datos](docs/upgrading-databases.md)

## Seguridad

Solo desarrollo local o redes de confianza. En produccion: secretos externos, TLS, firewalls y servicios gestionados.
