# Proyecto SO I – Mattermost con Podman rootless en AWS EC2

Servicio: **Mattermost** (Team Edition) + **PostgreSQL 16** + **Caddy** (proxy HTTPS), en una instancia EC2
AlmaLinux 9 (t3.small). Todo corre con **Podman rootless** bajo el usuario `mm`, administrado por **Quadlet** (systemd de usuario).

URL pública: https://reinicia-y-reza.duckdns.org

## Arquitectura
Internet → **caddy** (80/443) → **mm** (8065, interno) → **db** (5432, interno). Red interna `mmnet`.
Volúmenes persistentes en `~/mm/{pgdata,config,data,logs,plugins,caddy_data}`.

## Despliegue (resumen)
1. EC2 AlmaLinux 9, Elastic IP, Security Group con 22, 80 y 443.
2. Como `ec2-user`: `sudo dnf install -y podman git sysstat`; crear usuario `mm`; `loginctl enable-linger mm`;
   `net.ipv4.ip_unprivileged_port_start=80` en `/etc/sysctl.d/`; delegar cgroups
   (`Delegate=cpu cpuset io memory pids` en `/etc/systemd/system/user@.service.d/delegate.conf`).
3. Como `mm`: `mkdir -p ~/mm/{pgdata,config,data,logs,plugins,caddy_data}`; copiar `Caddyfile` a `~/mm/`.
4. Copiar `quadlet/*` a `~/.config/containers/systemd/` y **cambiar `CAMBIAR` por la contraseña real**.
5. `systemctl --user daemon-reload && systemctl --user start db mm caddy`
6. Prueba: `sudo reboot` (como `ec2-user`) → los tres servicios arrancan solos.

> Las contraseñas del repositorio son marcadores (`CAMBIAR`). No subir contraseñas reales ni archivos `.pem`.

## Fallas (carpeta `scripts/`)
Ejecutar como `mm`, **desde la carpeta `scripts/`**. Cada script tiene la sección PREDIGO para completar antes de correrlo.

| Script | Caso |
|---|---|
| `b1_zombi.sh` | B1 Proceso zombi/huérfano o servicio que no reinicia |
| `b2_cpu.sh` | B2 Un proceso acapara la CPU |
| `b3_disco.sh` | B3 Disco lleno / inodos |
| `i1_oom.sh` | I1 Fuga de memoria y OOM killer |
| `i2_io.sh` | I2 Disco saturado por I/O |
| `a1_uid.sh` | A1 Permisos rotos por mapeo de UID (rootless) |
| `a2_privilegios.sh` | A2 Contenedor con permisos de más |

Las fichas (Predigo, Mido, Explico y Corrijo) van en `fichas/` con `PLANTILLA_FICHA.md`; la evidencia en `evidencias/`.
