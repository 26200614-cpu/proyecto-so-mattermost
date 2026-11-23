#!/usr/bin/env bash
# I2 - Disco saturado por I/O.   Ejecutar como usuario mm (iostat viene de sysstat).
# PREDIGO (completar antes): ...
URL=${1:-https://reinicia-y-reza.duckdns.org}
medir() { for i in 1 2 3; do curl -o /dev/null -s -w '%{time_total}s\n' "$URL/api/v4/system/ping"; done; }
echo "== ANTES: latencia =="; medir
lsblk

echo; echo "== PROVOCAR: escrituras intensas de Postgres (base aparte: pgtest) =="
podman exec db createdb -U mmuser pgtest
podman exec db pgbench -i -s 50 -U mmuser pgtest

echo; echo "== MIDO: iostat en segundo plano mientras corre pgbench =="
iostat -x 1 40 > ../evidencias/iostat_i2.txt &
podman exec db pgbench -c 16 -T 30 -U mmuser pgtest | tail -12
medir   # latencia durante la carga (ejecutar tambien enviando mensajes en Mattermost)
wait
tail -25 ../evidencias/iostat_i2.txt   # mirar r_await/w_await y %util

# CORRECCION: limpiar y/o limitar la escritura:
#   podman exec db dropdb -U mmuser pgtest
#   (limite)  podman run ... --device-write-bps /dev/nvme0n1:20mb ...
