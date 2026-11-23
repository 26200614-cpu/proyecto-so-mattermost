#!/usr/bin/env bash
# B3 - Disco lleno o inodos agotados.   Ejecutar como usuario mm.
# PREDIGO (completar antes): ...
# Se escribe DENTRO del contenedor porque el volumen pertenece a un UID mapeado (:U).
# ATENCION: deja ~400 MB libres para no romper SSH ni systemd.
echo "== ANTES =="; df -h /home/mm; df -i /home/mm

LIBRE_MB=$(df --output=avail -BM /home/mm | tail -1 | tr -dc '0-9')
LLENAR=$((LIBRE_MB - 400))
echo; echo "== PROVOCAR: crear archivo de ${LLENAR} MB en el volumen de datos =="
podman exec mm sh -c "fallocate -l ${LLENAR}M /mattermost/data/relleno.bin || dd if=/dev/zero of=/mattermost/data/relleno.bin bs=1M count=${LLENAR}"

echo; echo "== MIDO =="; df -h /home/mm; df -i /home/mm
echo "-> Ahora, en Mattermost, subir un adjunto grande y capturar el error."
podman logs --tail 20 mm

echo; echo "== INODOS: en XFS (AlmaLinux) se asignan dinamicamente; muy dificil agotarlos. Documentar df -i. =="

# CORRECCION (ejecutar despues de capturar la evidencia):
#   podman exec mm rm /mattermost/data/relleno.bin && df -h /home/mm
