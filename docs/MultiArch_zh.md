# KyberBench 多架构镜像构建指南

## 概述

KyberBench 现在支持 Docker 多架构镜像构建，允许您在单个构建命令中为多个平台（linux/amd64、linux/arm64 等）构建镜像。

## 核心概念

### 什么是多架构镜像？

传统 Docker 镜像是"一个镜像对应一个平台"。多架构镜像的本质是一个 **manifest list**，它指向不同平台的实际镜像。当执行 `docker pull` 时，Docker 会自动根据当前机器的架构选择匹配版本。

### 涉及的核心架构

| 架构标识 | 典型设备 |
|----------|----------|
| linux/amd64 | 绝大多数云服务器、传统 PC |
| linux/arm64 | Apple Silicon Mac、树莓派 4、AWS Graviton |

## 快速开始

### 1. 环境准备

```bash
# 在 bench 目录执行
cd bench

# 安装 QEMU binfmt 支持
make multiarch-setup
```

### 2. 创建 Multi-Arch Builder

```bash
# 创建并启用多架构 builder
make multiarch-enable

# 或分步执行
make multiarch-create    # 创建 builder
make multiarch-use       # 使用该 builder
```

### 3. 构建多架构镜像

```bash
# 构建所有镜像的多个架构版本
make multiarch-build

# 构建特定镜像
make multiarch_build_develop

# 使用自定义平台列表
make multiarch-build BENCH_MULTIARCH_PLATFORMS="linux/amd64,linux/arm64"
```

### 4. 推送多架构镜像

```bash
# 构建并推送所有镜像
make multiarch-push

# 推送特定镜像
make multiarch_push_develop

# 使用自定义平台和仓库
make multiarch-push BENCH_MULTIARCH_PLATFORMS="linux/amd64,linux/arm64" BENCH_REPO_BASE=docker.io/myname
```

## 常用命令

### Builder 管理

| 命令 | 说明 |
|------|------|
| `make multiarch-setup` | 安装 QEMU binfmt 支持 |
| `make multiarch-create` | 创建多架构 builder |
| `make multiarch-remove` | 删除 builder |
| `make multiarch-use` | 切换到多架构 builder |
| `make multiarch-default` | 切换回默认 builder |
| `make multiarch-info` | 查看 builder 信息 |

### 构建命令

| 命令 | 说明 |
|------|------|
| `make multiarch-build` | 构建所有镜像的多架构版本 |
| `make multiarch_build_<IMAGE>` | 构建特定镜像 |
| `make multiarch-all` | 构建并检查所有镜像的 manifest |
| `make multiarch-inspect_<IMAGE>` | 检查特定镜像的 manifest |

### 推送命令

| 命令 | 说明 |
|------|------|
| `make multiarch-push` | 构建并推送所有镜像 |
| `make multiarch_push_<IMAGE>` | 构建并推送特定镜像 |
| `make multiarch-all-push` | 推送所有镜像 |

### CI/CD 命令

| 命令 | 说明 |
|------|------|
| `make multiarch-ci` | CI 环境下的多架构构建和推送 |

## 高级用法

### 自定义平台列表

```bash
# 只构建 amd64
make multiarch-build BENCH_MULTIARCH_PLATFORMS="linux/amd64"

# 构建 amd64 和 arm64
make multiarch-build BENCH_MULTIARCH_PLATFORMS="linux/amd64,linux/arm64"

# 构建所有三种架构
make multiarch-build BENCH_MULTIARCH_PLATFORMS="linux/amd64,linux/arm64,linux/arm/v7"
```

### 自定义 Builder 名称

```bash
# 使用自定义 builder 名称
make multiarch-create BENCH_MULTIARCH_BUILDER=my-builder
make multiarch-build BENCH_MULTIARCH_BUILDER=my-builder
```

### 查看构建的镜像信息

```bash
# 检查镜像 manifest
make multiarch_inspect_develop

# 输出示例
# Name:      docker.io/superyongzhe/bench:develop
# MediaType: application/vnd.docker.distribution.manifest.list.v2+json
# Manifests:
#   Name:      docker.io/superyongzhe/bench:develop@sha256:abc123...
#   Platform: linux/amd64
#   Name:      docker.io/superyongzhe/bench:develop@sha256:def456...
#   Platform: linux/arm64
```

## GitHub Actions 集成

在 CI 环境中使用多架构构建：

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

## 性能优化

### QEMU 模拟 vs 交叉编译

QEMU 模拟构建 ARM 镜像比原生构建慢 3-5 倍。对于支持交叉编译的项目，建议：

1. 在 Dockerfile 中使用 `TARGETARCH` 变量
2. 设置 `GOARCH`、`CC` 等环境变量进行交叉编译
3. 避免在构建过程中运行二进制文件

### Dockerfile 示例

```dockerfile
FROM --platform=$BUILDPLATFORM alpine:latest AS builder
ARG TARGETPLATFORM
ARG TARGETARCH

# 交叉编译
RUN apk add --no-cache gcc musl-dev && \
    CC=${TARGETARCH}-linux-musl-gcc \
    CGO_ENABLED=1 \
    GOARCH=${TARGETARCH} \
    go build -o myapp .

FROM alpine:latest
COPY --from=builder /myapp /usr/local/bin/
CMD ["myapp"]
```

## 常见问题

### 1. 如何检查基础镜像是否支持多架构？

```bash
docker buildx imagetools inspect alpine:latest
```

### 2. 如何在本地测试另一个架构的镜像？

```bash
# 在 x86 机器上运行 ARM 镜像
docker run --platform linux/arm64 myimage:latest
```

### 3. 构建缓存失效怎么办？

多平台构建的缓存是按平台分别存储的。切换 builder 实例会导致缓存全部丢失。使用 GitHub Actions 时，建议使用 `type=gha` 缓存后端。

### 4. 构建失败常见原因

- 基础镜像不支持目标架构
- `apt-get install` 安装了错误架构的包
- QEMU binfmt 未正确安装

## 参考资料

- [Docker 多架构构建官方文档](https://docs.docker.com/build/building/multi-platform/)
- [Docker Buildx 官方文档](https://docs.docker.com/buildx/working-with-buildx/)
- [QEMU User Mode](https://www.qemu.org/docs/master/user/index.html)
