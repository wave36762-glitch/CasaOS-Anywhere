# casaos-docker-installer

Run [CasaOS](https://casaos.io) on any Linux distribution that can run Docker,
including ones CasaOS doesn't officially support. It's a small install script
around the [`dockurr/casa`](https://hub.docker.com/r/dockurr/casa) image.

Works on **amd64** and **arm64**. Unofficial: not affiliated with IceWhale or dockur.

## Quick start

Requirements: Linux, Docker (the script installs it if missing), sudo.

```bash
curl -fsSL https://raw.githubusercontent.com/wave36762-glitch/CasaOS-Anywhere/refs/heads/main/Install.sh | sudo bash
wget -qO- https://raw.githubusercontent.com/wave36762-glitch/CasaOS-Anywhere/refs/heads/main/Install.sh | sudo bash
sudo bash Install.sh
```

Then open `http://<your-ip>:8080`.

## Versions

| Version | Host Docker socket | USB | Host CPU/sys stats | Host filesystem (`/:/mnt/root`) |
|---|---|---|---|---|
| minimal | yes | no | no | no |
| standard | yes | yes | yes | no |
| full | yes | yes | yes | yes |

## How it works

CasaOS runs in a container and shares the **host's** Docker through
`/var/run/docker.sock`. Apps you install are normal containers on your host
(not nested), so `docker ps` shows everything and they keep their own restart
policies. Your data lives in `/DATA`.

## Security

The container runs with `--privileged` and has access to the Docker socket.
That is equivalent to root on the host, even in versions without the
filesystem mount. Only use it on machines where you accept that.

## Uninstall

```bash
bash uninstall.sh
```

## Troubleshooting

- Port 8080 already in use: change the `-p` mapping in the script.
- `docker run` fails on `/dev/bus/usb`: use the minimal version.

## Credits

CasaOS by IceWhale, container image by dockur.
