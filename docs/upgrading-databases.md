# Subir version mayor de una base de datos

Patron comun (PostgreSQL, MariaDB, MongoDB):

1. Respaldar con el contenedor en la version antigua.
2. Parar el servicio y borrar su volumen de datos.
3. Cambiar la imagen en `docker-compose.yml` y `make update-digests` si aplica.
4. Levantar el servicio (volumen vacio; los init vuelven a ejecutarse).
5. Restaurar el backup.
6. Verificar.

Los scripts de init **no se repiten** si el volumen ya existia. Por eso hay que borrar el volumen al cambiar de version mayor.

Los nombres de volumen llevan el prefijo del proyecto (`development_postgresql`, etc.). Listalos con `docker volume ls`.

## PostgreSQL (`postgis/postgis:18-3.6`)

```bash
docker compose up -d postgresql
docker exec postgresql pg_dumpall -U postgres --clean --if-exists > backup-postgresql.sql

docker compose stop postgresql
docker volume rm development_postgresql

# Actualizar tag en x-postgres-image y make update-digests

docker compose up -d postgresql
docker exec -i postgresql psql -U postgres < backup-postgresql.sql
docker exec postgresql psql -U postgres -c '\l'
```

Solo Keycloak: `pg_dump -U postgres -Fc keycloak` / `pg_restore -U postgres -d keycloak`.

## MariaDB (`mariadb:12`)

```bash
docker compose up -d mariadb
docker exec mariadb mysqldump -u root -proot --all-databases --single-transaction > backup-mariadb.sql

docker compose stop mariadb
docker volume rm development_mariadb

docker compose up -d mariadb
docker exec -i mariadb mysql -u root -proot < backup-mariadb.sql
```

## MongoDB

```bash
docker compose up -d mongodb
docker exec mongodb mongodump \
  --username=mongodb --password=mongodb --authenticationDatabase=admin \
  --archive > backup-mongodb.archive

docker compose stop mongodb
docker volume rm development_mongodb_data development_mongodb_config

docker compose up -d mongodb
docker exec -i mongodb mongorestore \
  --username=mongodb --password=mongodb --authenticationDatabase=admin \
  --archive < backup-mongodb.archive
```

No cambies solo la imagen sobre el mismo volumen: el motor rechazara los datos de la version anterior.
