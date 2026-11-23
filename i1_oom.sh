#!/usr/bin/env bash
# I1 - Fuga de memoria y OOM killer.   Ejecutar como usuario mm.
# PREDIGO (completar antes): Mattermost usa ~700 MB en reposo; con un limite menor deberia morir por OOM.
echo "== ANTES =="; podman stats --no-stream mm db
podman inspect mm --format 'OOMKilled={{.State.OOMKilled}} Memoria={{.HostConfig.Memory}}'

echo; echo "== PROVOCAR: limite bajo a la aplicacion (300 MB) =="
podman update --memory 300m --memory-swap 300m mm
# Para Postgres:  podman update --memory 100m --memory-swap 100m db
sleep 20

echo; echo "== MIDO =="
podman inspect mm --format 'OOMKilled={{.State.OOMKilled}} ExitCode={{.State.ExitCode}}'
for f in $(find /sys/fs/cgroup/user.slice/user-$(id -u).slice -name memory.events -path '*mm.service*' 2>/dev/null); do
  echo "$f"; cat "$f"; cat "$(dirname "$f")/memory.max"
done
systemctl --user status mm.service --no-pager | head -12
echo "Para el log del kernel (necesita sudo, usar ec2-user):  sudo journalctl -k | grep -i 'killed process'"

# CORRECCION: reiniciar el servicio (systemd recrea el contenedor SIN el limite), o subir el limite:
#   systemctl --user restart mm.service
