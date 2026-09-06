# Digital Independence Deployment

## Keep it simple, stupid! (KISS)

```bash
git clone https://github.com/ricalnet/digital-independence.git
cd digital-independence

./install-podman-on-debian.sh
```

> During installation, you'll want to add these registries to `/etc/containers/registries.conf`:
> ```
> unqualified-search-registries = ["docker.io", "ghcr.io", "dock.mau.dev"]
> ```

## Setting Up Your Environment

Use `dipen env` to create and edit `.env` files for the services you need:

```bash
dipen env <service1> <service2> <service3>
```

## Deploying Services

### Quick Start

Once configured, spin up your services with:

```bash
dipen up <service1> <service2> <service3>
```

You can then access them at `http://localhost:<port>`.

> The steps above work for most services out of the box. If a service isn't listed in the section below, you're good to go with the default setup.

## Service-Specific Tweaks

A few services need a little extra attention:

### element-web
```bash
cp digital-independence/element-web/config/element-web-config-example.json digital-independence/element-web/config/element-web-config.json
```

### immich
(optional, depends on `UPLOAD_LOCATION` in `.env`)
```bash
mkdir data
```

### jellyfin
(media path depends on `MEDIA_PATH` in `.env`, defaults to `./media`)
```bash
mkdir -p cache config media
```

### navidrome
(music path depends on `MEDIA_PATH` in `.env`, defaults to `./music`)
```bash
mkdir music
```

### open-webui
If you're using Ollama, just comment out the relevant sections in `compose.yaml` and `.env`.

### pi-hole
Optional but recommended for dnscrypt-proxy:
```bash
cp digital-independence/pi-hole/dnscrypt-config/dnscrypt-proxy.template.toml digital-independence/pi-hole/dnscrypt-config/dnscrypt-proxy.toml
```

### synapse and mautrix
These need a bit more setup. Check out the full guide here:  
[Matrix Synapse Self-Hosted Deployment Guide with Mautrix Bridge](https://docs.ricalnet.my.id/posts/panduan-deployment-matrix-synapse-self-hosted-dengan-mautrix-bridge-whatsapp-dan-telegram/)

## Exposing Services

### 🧅 Tor Hidden Service
Anonymous access through Tor network.
- 📖 [Tor Implementation Guide](https://docs.ricalnet.my.id/posts/panduan-implementasi-hidden-service-tor/)

### ☁️ Cloudflare Tunnel
Access without opening firewall ports.
- 📖 [Cloudflare Tunnel Guide](https://docs.ricalnet.my.id/posts/panduan-lengkap-mengonfigurasi-cloudflare-tunnel-untuk-ekspos-layanan-lokal/)
