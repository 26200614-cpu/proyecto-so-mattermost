#!/usr/bin/env bash
# A1 - Volumen con permisos rotos por el mapeo de UID (rootless).   Ejecutar como usuario mm.
# PREDIGO (completar antes): ...
mkdir -p ~/prueba_uid
echo "== Mapeo de UID del usuario (contenedor -> host) =="
podman unshare cat /proc/self/uid_map
grep "^$(whoami):" /etc/subuid

echo; echo "== PROVOCAR: carpeta con dueno 1234 (dentro del userns) =="
podman unshare chown 1234:1234 ~/prueba_uid
ls -ldn ~/prueba_uid                      # UID real en el host (subuid + 1233)
podman unshare ls -ldn ~/prueba_uid       # UID visto desde el espacio de nombres

echo; echo "== MIDO: Mattermost como usuario 2000 intenta escribir =="
podman run --rm --user 2000 --entrypoint sh -v ~/prueba_uid:/mattermost/data:Z \
  docker.io/mattermost/mattermost-team-edition:latest -c 'id; touch /mattermost/data/x && echo OK || echo "Permission denied"'

echo; echo "== CORRECCION: opcion :U (chown automatico al UID del contenedor) =="
podman run --rm --user 2000 --entrypoint sh -v ~/prueba_uid:/mattermost/data:Z,U \
  docker.io/mattermost/mattermost-team-edition:latest -c 'id; touch /mattermost/data/x && echo OK || echo "Permission denied"'
ls -ldn ~/prueba_uid
