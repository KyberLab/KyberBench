# KyberBench

[English Version](README.md) | 中文版本

KyberBench是一个基于容器的虚拟开发环境构建项目。它提供了一个全面的框架，用于创建、管理和部署各种虚拟化系统的容器化开发环境。支持通过Jinjia2模版来增强Dockerfile的可编程性，集成dockpin等方法来提升开发环境的一致性和可追溯性。

## 目录结构

```
bench/
├── Build.mk           # 构建配置
├── Main.mk            # 主要基准测试规则
├── Makefile           # 主 Makefile
├── Run.mk             # 运行配置
├── image/             # Docker 镜像和配置
│   ├── config/        # 配置文件
│   ├── dockerfile/    # Docker 配置
│   │   ├── arm/       # ARM Docker 配置
│   │   ├── develop/   # 开发环境
│   │   ├── dockpin/   # Dockpin 配置
│   │   ├── linaro/    # Linaro 工具链环境
│   │   ├── md/        # Markdown 文档环境
│   │   ├── nodejs/    # Node.js 环境
│   │   ├── python3/   # Python 3 环境
│   │   ├── qemu/      # QEMU 仿真环境
│   │   ├── rockpi5b/  # RockPI 5B 环境
│   │   ├── sshd/      # SSH 服务器环境
│   │   ├── system/    # 系统环境
│   │   ├── ubuntu/    # Ubuntu 环境
│   │   ├── virgl/     # VirGL 环境
│   │   └── virt-aarch64/ # 虚拟化环境
│   └── scripts/       # 实用脚本
└── rules/             # 构建规则和工具
    ├── Main.mk        # 主要规则文件
    ├── config/        # 配置规则
    ├── macro/         # 宏定义
    ├── LICENSE        # 许可证文件
    ├── README.md      # 英文使用说明
    └── README_zh.md   # 中文使用说明
```

## 功能特性

### 1. 基于容器的开发环境

- **隔离环境**：容器化开发环境确保一致性和可重现性
- **多平台支持**：适用于各种目标平台的 Docker 配置
- **预配置工具链**：现成的交叉编译和原生开发工具链
- **可重现构建**：不同开发系统间的一致环境

### 2. 虚拟环境管理

- **虚拟化支持**：用于管理和测试虚拟化环境的工具
- **仿真集成**：基于 QEMU 的仿真，无需物理硬件即可进行测试
- **真实硬件支持**：与实际硬件平台的集成
- **网络配置**：用于复杂测试场景的虚拟网络设置

### 3. 全面的构建系统

- **模块化构建规则**：可重用的构建规则和工具，提高开发效率
- **配置管理**：针对不同项目需求的灵活配置系统
- **依赖管理**：构建依赖的自动处理
- **版本控制集成**：用于版本跟踪和管理的 Git 集成

### 4. 开发工作流工具

- **交互式 Shell 访问**：轻松访问容器化环境
- **文件系统集成**：与主机文件系统的无缝集成
- **日志和监控**：用于开发和调试的全面日志记录
- **文档生成**：用于生成项目文档的工具

### 5. 跨平台开发

- **交叉编译支持**：为不同架构构建代码
- **多架构镜像**：支持多种架构的 Docker 镜像
- **平台特定优化**：用于针对特定平台优化代码的工具

## 快速开始

### 1. 设置开发环境

```bash
# 构建特定的 Docker 镜像
make build_<image-name>
```

### 2. 启动容器化环境

```bash
# 在 Docker 环境中启动交互式 shell
make run_<image-name>

# 在 Docker 中运行特定命令
make run_<image-name> USER_RUN_CMD="<command>"
```

## Docker 镜像

### 可用的开发环境

- **arm**：ARM 架构特定环境
- **develop**：通用开发环境，包含全面的工具
- **dockpin**：用于包管理的 Dockpin 配置
- **linaro**：用于交叉编译的 Linaro 工具链环境
- **md**：支持 Markdown 的文档生成环境
- **nodejs**：用于 JavaScript 开发的 Node.js 运行环境
- **python3**：用于 Python 开发的 Python 3 环境
- **qemu**：QEMU 仿真环境，无需物理硬件即可进行测试
- **rockpi5b**：RockPI 5B 特定环境，用于硬件测试
- **sshd**：用于远程访问的 SSH 服务器环境
- **system**：包含 essential 工具的基础系统环境
- **ubuntu**：基于 Ubuntu 的环境，具有各种配置
- **virgl**：用于加速图形的 VirGL 环境
- **virt-aarch64**：虚拟化特定环境，用于虚拟化开发

### 实用脚本

- **kyberdocker**：用于支持 Dockerfile Jinja2 模板的脚本
- **kyberinstall**：用于根据 dockpin 的 apt lock 文件安装软件包和管理依赖的脚本

---

## KyberDocker 模板系统

### 1. 原理说明

KyberDocker 是 KyberBench 提供的一个基于 **Jinja2 + YAML** 的 Dockerfile 模板渲染工具。它允许您：

- 使用 Jinja2 模板语法编写可复用的 Dockerfile 模板
- 通过 YAML 配置文件管理模板变量
- 实现 Dockerfile 的可编程化和参数化

**工作流程**：

```
Dockerfile.j2 (模板) + KyberDocker.yaml (变量) → Dockerfile (输出)
```

### 2. J2 模板配置

#### 2.1 模板文件

每个镜像目录下可以包含 `Dockerfile.j2` 文件，使用 Jinja2 语法：

```jinja2
# Dockerfile.j2 示例
FROM {{ BENCH_NAME }}:python3

# 使用变量
COPY dockpin-apt.lock /tmp
RUN sudo /usr/local/sbin/dockpin apt install -p /tmp/dockpin-apt.lock

# 条件判断
{% if INSTALL_PYTHON_PACKAGES %}
COPY requirements.txt /tmp/
RUN sudo -H pip install --no-cache-dir -r /tmp/requirements.txt
{% endif %}

# 循环
{% for tool in TOOLS %}
RUN sudo apt-get install -y {{ tool }}
{% endfor %}
```

#### 2.2 Jinja2 语法支持

| 语法 | 说明 | 示例 |
|------|------|------|
| `{{ var }}` | 变量引用 | `{{ BENCH_NAME }}` |
| `{% if %}` | 条件判断 | `{% if DEBUG %}` |
| `{% for %}` | 循环 | `{% for item in list %}` |
| `{% set %}` | 变量赋值 | `{% set version = "1.0" %}` |
| `{{ var | filter }}` | 过滤器 | `{{ name | upper }}` |

### 3. 变量配置文件

#### 3.1 全局配置

全局配置文件位于 `image/config/KyberDocker.yaml`：

```yaml
# image/config/KyberDocker.yaml
BENCH_NAME: "superyongzhe/bench"
BENCH_INITRC: "/etc/profile.d/init.sh"
BENCH_IMG_DISTRO: "ubuntu"
```

#### 3.2 镜像特定配置

每个镜像目录下可以创建 `KyberDocker.yaml`，覆盖全局配置：

```yaml
# image/dockerfile/linaro/KyberDocker.yaml
LINARO_GCC_URL: https://releases.linaro.org/components/toolchain/binaries/7.3-2018.05/aarch64-linux-gnu/gcc-linaro-7.3.1-2018.05-x86_64_aarch64-linux-gnu.tar.xz
LINARO_GCC_PACKAGE_NAME: gcc-linaro-7.3.1-2018.05-x86_64_aarch64-linux-gnu.tar.xz
```

### 4. 变量优先级

变量按照以下优先级进行合并（后面的会覆盖前面的）：

| 优先级 | 来源 | 说明 |
|--------|------|------|
| 1 (最低) | `-c` 指定的配置文件 | 通过命令行 `-c` 参数指定的 YAML 文件 |
| 2 | 全局配置 `image/config/KyberDocker.yaml` | 全局默认配置 |
| 3 | 镜像配置目录 `KyberDocker.yaml` | 当前镜像目录下的配置 |
| 4 | `-w` 工作目录下的 `KyberDocker.yaml` | 通过 `-w` 指定的工作目录中的配置 |
| 5 (最高) | `-e` 命令行变量 | 通过 `-e name=value` 指定的变量 |

**优先级示意图**：

```
┌─────────────────────────────────────────────────────────────┐
│  5. -e name=value           (命令行变量)                    │
│      ↓ 覆盖                                                 │
│  4. -w 工作目录/KyberDocker.yaml                            │
│      ↓ 覆盖                                                 │
│  3. 镜像目录/KyberDocker.yaml                               │
│      ↓ 覆盖                                                 │
│  2. image/config/KyberDocker.yaml    (全局配置)             │
│      ↓ 覆盖                                                 │
│  1. -c 指定的配置文件       (最低优先级)                     │
└─────────────────────────────────────────────────────────────┘
```

### 5. kyberdocker 命令用法

```bash
# 基本用法（使用默认配置）
./kyberdocker

# 指定工作目录
./kyberdocker -w /path/to/workdir

# 指定自定义配置文件
./kyberdocker -c myconfig.yaml

# 指定模板文件
./kyberdocker -t Dockerfile.j2

# 指定输出文件
./kyberdocker -o output/Dockerfile

# 添加命令行变量（最高优先级）
./kyberdocker -e BENCH_NAME=myrepo/bench -e DEBUG=true

# 完整示例
./kyberdocker -w ./bench -c config.yaml -t Dockerfile.j2 -o Dockerfile -e VERSION=1.0
```

### 6. 命令行参数说明

| 参数 | 说明 | 默认值 |
|------|------|--------|
| `-w` | 工作目录 | 当前目录 |
| `-c` | YAML 配置文件路径 | `KyberDocker.yaml` |
| `-t` | Jinja2 模板文件路径 | `Dockerfile.j2` |
| `-o` | 输出 Dockerfile 路径 | `Dockerfile` |
| `-e` | 自定义变量（格式：name=value） | 无 |

### 7. 实际应用示例

#### 示例 1：构建特定架构的镜像

```yaml
# image/dockerfile/virt-aarch64/KyberDocker.yaml
ARCH: aarch64
CROSS_COMPILE: aarch64-linux-gnu-
QEMU_ARCH: aarch64
```

```jinja2
# Dockerfile.j2
FROM {{ BENCH_NAME }}:system

RUN sudo apt-get install -y qemu-system-{{ QEMU_ARCH }}
ENV CROSS_COMPILE={{ CROSS_COMPILE }}
```

#### 示例 2：条件安装依赖

```yaml
# KyberDocker.yaml
INSTALL_GCC: true
INSTALL_CLANG: false
TOOLS:
  - git
  - vim
  - make
```

```jinja2
# Dockerfile.j2
FROM {{ BENCH_NAME }}:ubuntu

{% if INSTALL_GCC %}
RUN sudo apt-get install -y gcc g++
{% endif %}

{% if INSTALL_CLANG %}
RUN sudo apt-get install -y clang
{% endif %}

{% for tool in TOOLS %}
RUN sudo apt-get install -y {{ tool }}
{% endfor %}
```

#### 示例 3：使用命令行覆盖变量

```bash
# 使用默认配置构建
./kyberdocker

# 使用自定义 BENCH_NAME
./kyberdocker -e BENCH_NAME=myregistry/mybench

# 开启调试模式
./kyberdocker -e DEBUG=true -e LOG_LEVEL=verbose
```

### 8. 配置文件查找顺序

当使用 `-w` 参数指定工作目录时，配置文件的查找顺序为：

1. 当前命令执行目录
2. `-w` 指定的工作目录

模板文件和输出文件的路径解析遵循相同规则。

---

## 构建规则和工具

- **环境管理**：用于设置和配置开发环境的规则
- **容器编排**：用于管理 Docker 容器和镜像的工具
- **构建自动化**：用于自动化常见构建任务的宏
- **配置管理**：针对不同环境的灵活配置系统
- **版本控制**：用于版本跟踪和管理的 Git 集成
- **交叉编译支持**：用于为不同架构交叉编译的工具

有关更多详细信息，请参阅 [规则文档](rules/README.md)。

## 许可证

KyberBench 采用 Apache License 2.0 开源许可证。有关具体条款，请参阅 [LICENSE](LICENSE) 文件。

## 贡献

欢迎贡献和建议。请确保您遵循项目的代码风格和贡献指南。一些贡献方式包括：

- 添加新的容器化开发环境
- 改进现有的 Docker 配置
- 扩展构建规则和工具
- 编写文档和示例
- 在不同硬件平台上进行测试

---

**KyberBench**
基于容器的虚拟开发环境构建器
版权所有 (c) 2025-2026，Kyber 开发团队，保留所有权利。
