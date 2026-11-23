#!/usr/bin/env bash
# B2 - Un proceso acapara la CPU y afecta a otro.   Ejecutar como usuario mm.
# PREDIGO (completar antes): ...
URL=${1:-https://reinicia-y-reza.duckdns.org}
medir() { for i in 1 2 3 4 5; do curl -o /dev/null -s -w '%{time_total}s\n' "$URL/api/v4/system/ping"; done; }

echo "CPUs disponibles: $(nproc)"
echo "== ANTES: tiempo de respuesta de Mattermost =="; medir

echo; echo "== PROVOCAR: contenedor vecino con 4 bucles de CPU (sin limite) =="
podman rm -f hog >/dev/null 2>&1
podman run -d --name hog docker.io/library/alpine sh -c 'for i in 1 2 3 4; do (while :; do :; done) & done; wait'
sleep 5
echo "== DURANTE =="; medir
podman stats --no-stream

echo; echo "== CORRECCION: limitar el vecino a 0.5 CPU (cgroup cpu.max) =="
podman rm -f hog >/dev/null
podman run -d --name hog --cpus 0.5 docker.io/library/alpine sh -c 'for i in 1 2 3 4; do (while :; do :; done) & done; wait'
sleep 5
echo "== DESPUES =="; medir
podman stats --no-stream
cat /sys/fs/cgroup/user.slice/user-$(id -u).slice/user@$(id -u).service/user.slice/*/cpu.max 2>/dev/null | head -3

podman rm -f hog >/dev/null   # limpieza
