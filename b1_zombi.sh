#!/usr/bin/env bash
# B1 - Proceso zombi / huerfano, o servicio que no reinicia.   Ejecutar como usuario mm.
# PREDIGO (completar antes): ...
# AVISO: la parte final tumba Mattermost ~1 minuto. Avisar al equipo.
VER='ps -eo pid,ppid,stat,cmd'

echo "== ANTES: procesos de Mattermost y sleep (host) =="
$VER | awk 'NR==1 || /mattermost|sleep/' | grep -v awk

echo; echo "== PROVOCAR: padre (sleep 300) que NO hace wait() de su hijo (sleep 1) =="
podman exec -d mm sh -c 'sleep 1 & exec sleep 300'
sleep 3

echo; echo "== MIDO: buscar estado Z (zombi) =="
$VER | awk 'NR==1 || $3 ~ /Z/'

echo; echo "== HUERFANO: matar al padre; el zombi pasa a ser hijo del PID 1 del contenedor =="
PADRE=$($VER | awk '$3 !~ /Z/ && /sleep 300/ {print $1; exit}')
echo "Padre: $PADRE"; kill "$PADRE" 2>/dev/null
sleep 2
$VER | awk 'NR==1 || $3 ~ /Z/ || /bin\/mattermost/'

echo; echo "== SERVICIO QUE NO REINICIA?: matar el proceso principal; systemd debe reiniciarlo =="
date
podman kill --signal KILL mm
sleep 5
systemctl --user status mm.service --no-pager | head -12
journalctl --user -u mm.service -n 12 --no-pager
podman ps

# CORRIJO (zombis): ejecutar con init. En ~/.config/containers/systemd/mm.container agregar bajo [Container]:
#     RunInit=true        (si falla:  PodmanArgs=--init)
#   luego: systemctl --user daemon-reload && systemctl --user restart mm.service
# y repetir la prueba de zombi/huerfano: el init del contenedor hace wait() y el zombi desaparece.
