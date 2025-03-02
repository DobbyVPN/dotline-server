# Server docker images

## AWG server docker image

Wrapper for the `amneziavpn/amneziawg-go` docker image with Python3, required dependencies and [awg/](../awg/) folder added.

### Build

```bash
docker build -f docker/Dockerfile-awg-server -t awg-server:latest .
```

## Outline server docker image

Wrapper for the `quay.io/outline/shadowbox` docker image with Python3, required dependencies and [outline/](../outline/) folder added.

### Build

```bash
docker build -f docker/Dockerfile-outline-server -t outline-server:latest .
```

## Cloak server docker image

### Build

```bash
cd docker
docker build -f Dockerfile-cloak-server -t cloak-server:latest .
```
