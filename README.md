# PXE Boot Cache

Transparent proxy that serves as a cache for the pxe boot files (CoreOS).
It will check the stable release stream for updates and serves always the latest release.
---

## Features

* **Always up-to-date**: resolves the latest release from Fedora’s `stable.json` stream metadata.
* **Local file cache**: artifacts are stored under `/var/cache/nginx/fcos"` and reused for subsequent boots.
* **Stampede protection**: only one worker downloads at a time; concurrent requests wait for the file to be cached.
* **Container-native**: packaged in Docker/Podman, published to GHCR.
* **Transparent to PXE**: clients only ever see your local endpoint (e.g. `http://coreos.rednet.lan/pxe/kernel`).

---

## Endpoints

| Endpoint                  | Description                                                                             |
| ------------------------- | --------------------------------------------------------------------------------------- |
| `/pxe/kernel`             | Latest FCOS kernel (`x86_64 / metal / pxe`)                                             |
| `/pxe/initramfs`          | Latest FCOS initramfs (`x86_64 / metal / pxe`)                                          |
| `/pxe/rootfs`             | Latest FCOS rootfs (`x86_64 / metal / pxe`)                                             |
| `/pxe/version.json` (opt) | Compact JSON summary with stream, architecture, release, and artifact URLs + checksums  |

All artifact responses include cache headers and an `X-Cache-Status` header (`LOCAL-HIT`, `LOCAL-MISS`) to help you confirm caching behavior.
When signature verification succeeds, responses also include an `X-FCOS-Signature: OK` header.

---

## How It Works

1. **Resolve metadata**: On the first request, the service fetches `https://builds.coreos.fedoraproject.org/streams/stable.json` and caches it (ETag-aware).
2. **Pick artifact URL**: For the requested component (`kernel`, `initramfs`, `rootfs`), it extracts the canonical `location` value.
3. **Download & verify**:
   * If not cached, downloads the file into a temp location.
   * Moves the file into `/var/cache/coreos-files/{component}`.
4. **Serve locally**: On subsequent requests, files are served directly from disk (with support for HTTP range requests).
5. **Revalidation**: The service automatically checks Fedora’s ETag for new releases; if updated, re-downloads and re-verifies the artifacts.

---

## Example Usage

Point your PXE boot config at your local endpoint:

```ipxe
kernel  http://coreos.rednet.lan/pxe/kernel \
        initrd=main \
        coreos.live.rootfs_url=http://coreos.rednet.lan/pxe/rootfs \
        ignition.firstboot \
        ignition.platform.id=metal \
        ignition.config.url=${CONFIGURL}
initrd --name main http://coreos.rednet.lan/pxe/initramfs
boot
```

Verify caching and integrity:

```bash
# First request (MISS)
curl -I http://localhost:8080/pxe/kernel | grep X-Cache-Status

# Second request (HIT)
curl -I http://localhost:8080/pxe/kernel | grep X-Cache-Status

# Metadata with hashes
curl -s http://localhost:8080/pxe/version.json | jq .
```

