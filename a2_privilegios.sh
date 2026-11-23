#!/usr/bin/env bash
# A2 - Contenedor con permisos de mas.   Ejecutar como usuario mm.
# PREDIGO (completar antes): ...
IMG=docker.io/library/alpine
mkdir -p ~/prueba && echo "secreto del host" > ~/prueba/dato.txt

echo "== 1) Configuracion normal =="
podman run --rm $IMG sh -c 'grep -E "CapEff|NoNewPrivs" /proc/self/status; ls /dev | wc -l'

echo; echo "== 2) --privileged =="
podman run --rm --privileged $IMG sh -c 'grep -E "CapEff|NoNewPrivs" /proc/self/status; ls /dev | wc -l'

echo; echo "== 3) volumen del host con permisos de escritura (-v ~/prueba:/host) =="
podman run --rm -v ~/prueba:/host:Z $IMG sh -c 'cat /host/dato.txt; touch /host/escrito_desde_contenedor && echo "PUDO ESCRIBIR EN EL HOST"'
ls -l ~/prueba

echo; echo "== 4) VERSION ENDURECIDA =="
podman run --rm --cap-drop=ALL --read-only --security-opt no-new-privileges $IMG \
  sh -c 'grep -E "CapEff|NoNewPrivs" /proc/self/status; touch /x 2>&1 || echo "Sistema de archivos de solo lectura"'

echo; echo "Decodificar capacidades (si capsh esta instalado):  capsh --decode=<valor CapEff>"
