FROM docker.io/overv/openstreetmap-tile-server@sha256:c8fd7a48e1afabfdd0dab55c5cc022ba880145846b950af9a00d8f8eb4b6d2fb

# Copiar el archivo de region
COPY chile-latest.osm.pbf /data/region.osm.pbf

# Ejecutar la importacion
RUN /run.sh import

# Punto de entrada
CMD ["/run.sh", "run"]
