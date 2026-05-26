# KyberBench Multi-Architecture Image Build Guide

## Overview

KyberBench now supports Docker multi-architecture image building, allowing you to build images for multiple platforms (linux/amd64, linux/arm64, etc.) in a single build command.

## Core Concepts

### What is Multi-Architecture Image?

Traditional Docker images are "one image for one platform". A multi-architecture image is essentially a **manifest list** that points to actual images for different platforms. When you run `docker pull`, Docker automatically selects the matching version based on your machine's architecture.

### Supported Architectures

| Architecture | Typical Devices |
|--------------|----------------|
| linux/amd64 | Most cloud servers, traditional PCs |
| linux/arm64 | Apple Silicon Mac, Raspberry Pi 4, AWS Graviton |

## Quick Start

### 1. Environment Setup

```bash
# Execute in bench directory
cd bench

# Install QEMU binfmt support
make multiarch-setup
```

### 2. Create Multi-Arch Builder

```bash
# Create and enable multi-arch builder
make multiarch-enable

# Or execute step by step
make multiarch-create    # Create builder
make multiarch-use       # Use the builder
```

### 3. Build Multi-Architecture Images

```bash
# Build all images for multiple architectures
make multiarch-build

# Build specific image
make multiarch_build_develop

# Use custom platform list
make multiarch-build BENCH_MULTIARCH_PLATFORMS="linux/amd64,linux/arm64"
```

### 4. Push Multi-Architecture Images

```bash
# Build and push all images
make multiarch-push

# Push specific image
make multiarch_push_develop

# Use custom platforms and registry
make multiarch-push BENCH_MULTIARCH_PLATFORMS="linux/amd64,linux/arm64" BENCH_REPO_BASE=docker.io/myname
```

## Common Commands

### Builder Management

| Command | Description |
|---------|-------------|
| `make multiarch-setup` | Install QEMU binfmt support |
| `make multiarch-create` | Create multi-arch builder |
| `make multiarch-remove` | Remove builder |
| `make multiarch-use` | Switch to multi-arch builder |
| `make multiarch-default` | Switch back to default builder |
| `make multiarch-info` | View builder information |

### Build Commands

| Command | Description |
|---------|-------------|
| `make multiarch-build` | Build all images for multiple architectures |
| `make multiarch_build_<IMAGE>` | Build specific image |
| `make multiarch-all` | Build and inspect all image manifests |
| `make multiarch-inspect_<IMAGE>` | Inspect specific image manifest |

### Push Commands

| Command | Description |
|---------|-------------|
| `make multiarch-push` | Build and push all images |
| `make multiarch_push_<IMAGE>` | Build and push specific image |
| `make multiarch-all-push` | Push all images |

### CI/CD Commands

| Command | Description |
|---------|-------------|
| `make multiarch-ci` | Multi-arch build and push for CI environments |

## Advanced Usage

### Custom Platform List

```bash
# Build only amd64
make multiarch-build BENCH_MULTIARCH_PLATFORMS="linux/amd64"

# Build amd64 and arm64
make multiarch-build BENCH_MULTIARCH_PLATFORMS="linux/amd64,linux/arm64"

# Build all three architectures
make multiarch-build BENCH_MULTIARCH_PLATFORMS="linux/amd64,linux/arm64,linux/arm/v7"
```

### Custom Builder Name

```bash
# Use custom builder name
make multiarch-create BENCH_MULTIARCH_BUILDER=my-builder
make multiarch-build BENCH_MULTIARCH_BUILDER=my-builder
```

### Inspect Built Images

```bash
# Check image manifest
make multiarch_inspect_develop

# Example output
# Name:      docker.io/superyongzhe/bench:develop
# MediaType: application/vnd.docker.distribution.manifest.list.v2+json
# Manifests:
#   Name:      docker.io/superyongzhe/bench:develop@sha256:abc123...
#   Platform: linux/amd64
#   Name:      docker.io/superyongzhe/bench:develop@sha256:def456...
#   Platform: linux/arm64
```

## GitHub Actions Integration

Use multi-arch builds in CI environments:

```yaml
name: Build Multi-Arch Image

on:
  push:
    tags: ['v*']

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Set up QEMU
        uses: docker/setup-qemu-action@v3

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3

      - name: Login to Docker Hub
        uses: docker/login-action@v3
        with:
          username: ${{ secrets.DOCKERHUB_USERNAME }}
          password: ${{ secrets.DOCKERHUB_TOKEN }}

      - name: Build and push
        run: |
          cd bench
          make multiarch-ci \
            BENCH_REPO_BASE=${{ secrets.DOCKERHUB_USERNAME }}/bench \
            BENCH_MULTIARCH_PLATFORMS="linux/amd64,linux/arm64"
```

## Performance Optimization

### QEMU Emulation vs Cross-Compilation

QEMU emulation for ARM images is 3-5x slower than native builds. For projects that support cross-compilation, we recommend:

1. Use `TARGETARCH` variable in Dockerfile
2. Set `GOARCH`, `CC` and other environment variables for cross-compilation
3. Avoid running binaries during build

### Dockerfile Example

```dockerfile
FROM --platform=$BUILDPLATFORM alpine:latest AS builder
ARG TARGETPLATFORM
ARG TARGETARCH

# Cross-compile
RUN apk add --no-cache gcc musl-dev && \
    CC=${TARGETARCH}-linux-musl-gcc \
    CGO_ENABLED=1 \
    GOARCH=${TARGETARCH} \
    go build -o myapp .

FROM alpine:latest
COPY --from=builder /myapp /usr/local/bin/
CMD ["myapp"]
```

## Troubleshooting

### 1. How to check if base image supports multi-arch?

```bash
docker buildx imagetools inspect alpine:latest
```

### 2. How to test another architecture locally?

```bash
# Run ARM image on x86 machine
docker run --platform linux/arm64 myimage:latest
```

### 3. Build cache invalidation?

Multi-platform build cache is stored separately per platform. Switching builder instances will cause all cache to be lost. When using GitHub Actions, we recommend using `type=gha` cache backend.

### 4. Common Build Failure Reasons

- Base image doesn't support target architecture
- `apt-get install` installed wrong architecture packages
- QEMU binfmt not properly installed

## References

- [Docker Multi-platform Build Documentation](https://docs.docker.com/build/building/multi-platform/)
- [Docker Buildx Documentation](https://docs.docker.com/buildx/working-with-buildx/)
- [QEMU User Mode](https://www.qemu.org/docs/master/user/index.html)
