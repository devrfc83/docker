# Importacion de tiles OSM

El servicio `osm` construye la imagen localmente e importa Chile en el **build** (`RUN /run.sh import` en `osm/Dockerfile`). La RAM pesada se consume en `docker compose build osm`, no en `docker compose up`.

## Primera construccion (~8 GB RAM)

1. Coloca el extracto en `osm/chile-latest.osm.pbf` (gitignored).
2. Libera RAM: `docker compose down`
3. En Docker Desktop, asigna al menos **6 GB** de memoria al motor.
4. Construye solo OSM:

```bash
docker compose build osm
docker compose up -d osm
```

Tiles en http://localhost:20006. Si el build falla con OOM (exit 137), sube RAM o construye en otra maquina.

## Limite del contenedor en ejecucion

El compose fija **768 MB** para el servicio `osm` (`command: run`). Para pruebas mas exigentes, sube temporalmente el ancla `x-mem-768m` y recrea:

```bash
docker compose up -d --force-recreate osm
```

## Cambiar de region

```bash
docker compose build --no-cache osm
docker compose up -d osm
```
