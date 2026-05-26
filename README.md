# KyberBench

[中文版本](README_zh.md) | English Version

KyberBench is a container-based project for building virtual development environments. It provides a comprehensive framework for creating, managing, and deploying containerized development environments for various virtualization systems. It supports Jinja2 templates to enhance Dockerfile programmability and integrates methods like dockpin to improve the consistency and traceability of development environments.

## Directory Structure

```
bench/
├── Build.mk           # Build configuration
├── Main.mk            # Main benchmark rules
├── Makefile           # Main Makefile
├── Run.mk             # Run configuration
├── image/             # Docker images and configurations
│   ├── config/        # Configuration files
│   ├── dockerfile/    # Docker configurations
│   │   ├── arm/       # ARM Docker configuration
│   │   ├── develop/   # Development environment
│   │   ├── dockpin/   # Dockpin configuration
│   │   ├── linaro/    # Linaro toolchain environment
│   │   ├── md/        # Markdown documentation environment
│   │   ├── nodejs/    # Node.js environment
│   │   ├── python3/   # Python 3 environment
│   │   ├── qemu/      # QEMU emulation environment
│   │   ├── rockpi5b/  # RockPI 5B environment
│   │   ├── sshd/      # SSH server environment
│   │   ├── system/    # System environment
│   │   ├── ubuntu/    # Ubuntu environment
│   │   ├── virgl/     # VirGL environment
│   │   └── virt-aarch64/ # Virtualization environment
│   └── scripts/       # Utility scripts
└── rules/             # Build rules and utilities
    ├── Main.mk        # Main rules file
    ├── config/        # Configuration rules
    ├── macro/         # Macro definitions
    ├── LICENSE        # License file
    ├── README.md      # English documentation
    └── README_zh.md   # Chinese documentation
```

## Features

### 1. Container-based Development Environments

- **Isolated Environments**: Containerized development environments for consistency and reproducibility
- **Multi-platform Support**: Docker configurations for various target platforms
- **Pre-configured Toolchains**: Ready-to-use toolchains for cross-compilation and native development
- **Reproducible Builds**: Consistent environments across different development systems

### 2. Virtual Environment Management

- **Virtualization Support**: Tools for managing and testing virtualized environments
- **Emulation Integration**: QEMU-based emulation for testing without physical hardware
- **Real Hardware Support**: Integration with actual hardware platforms
- **Network Configuration**: Virtual network setup for complex testing scenarios

### 3. Comprehensive Build System

- **Modular Build Rules**: Reusable build rules and utilities for efficient development
- **Configuration Management**: Flexible configuration system for different project needs
- **Dependency Management**: Automated handling of build dependencies
- **Version Control Integration**: Git integration for version tracking and management

### 4. Development Workflow Tools

- **Interactive Shell Access**: Easy access to containerized environments
- **File System Integration**: Seamless integration with host file systems
- **Logging and Monitoring**: Comprehensive logging for development and debugging
- **Documentation Generation**: Tools for generating project documentation

### 5. Cross-platform Development

- **Cross-compilation Support**: Build code for different architectures
- **Multi-architecture Images**: Docker images supporting multiple architectures
- **Platform-specific Optimizations**: Tools for optimizing code for specific platforms

## Quick Start

### 1. Set Up Development Environment

```bash
# Build specific Docker image
make build_<image-name>
```

### 2. Start Containerized Environment

```bash
# Start interactive shell in Docker environment
make run_<image-name>

# Run specific command in Docker
make run_<image-name> USER_RUN_CMD="<command>"
```

## Docker Images

### Available Development Environments

- **arm**: ARM architecture specific environment
- **develop**: General development environment with comprehensive tools
- **dockpin**: Dockpin configuration for package management
- **linaro**: Linaro toolchain environment for cross-compilation
- **md**: Documentation generation environment with Markdown support
- **nodejs**: Node.js runtime environment for JavaScript development
- **python3**: Python 3 environment for Python development
- **qemu**: QEMU emulation environment for testing without physical hardware
- **rockpi5b**: RockPI 5B specific environment for hardware testing
- **sshd**: SSH server environment for remote access
- **system**: Base system environment with essential utilities
- **ubuntu**: Ubuntu-based environment with various configurations
- **virgl**: VirGL environment for accelerated graphics
- **virt-aarch64**: Virtualization specific environment for virtualization development

### Utility Scripts

- **kyberdocker**: Script for supporting Dockerfile Jinja2 templates
- **kyberinstall**: Script for installing packages and managing dependencies based on dockpin's apt lock files

---

## KyberDocker Template System

### 1. Overview

KyberDocker is a Jinja2 + YAML based Dockerfile template rendering tool provided by KyberBench. It allows you to:

- Write reusable Dockerfile templates using Jinja2 syntax
- Manage template variables through YAML configuration files
- Implement Dockerfile programmability and parameterization

**Workflow**:

```
Dockerfile.j2 (template) + KyberDocker.yaml (variables) → Dockerfile (output)
```

### 2. J2 Template Configuration

#### 2.1 Template Files

Each image directory can contain a `Dockerfile.j2` file using Jinja2 syntax:

```jinja2
# Dockerfile.j2 Example
FROM {{ BENCH_NAME }}:python3

# Using variables
COPY dockpin-apt.lock /tmp
RUN sudo /usr/local/sbin/dockpin apt install -p /tmp/dockpin-apt.lock

# Conditional statements
{% if INSTALL_PYTHON_PACKAGES %}
COPY requirements.txt /tmp/
RUN sudo -H pip install --no-cache-dir -r /tmp/requirements.txt
{% endif %}

# Loops
{% for tool in TOOLS %}
RUN sudo apt-get install -y {{ tool }}
{% endfor %}
```

#### 2.2 Jinja2 Syntax Support

| Syntax | Description | Example |
|--------|-------------|---------|
| `{{ var }}` | Variable reference | `{{ BENCH_NAME }}` |
| `{% if %}` | Conditional | `{% if DEBUG %}` |
| `{% for %}` | Loop | `{% for item in list %}` |
| `{% set %}` | Variable assignment | `{% set version = "1.0" %}` |
| `{{ var | filter }}` | Filter | `{{ name | upper }}` |

### 3. Variable Configuration Files

#### 3.1 Global Configuration

Global configuration file located at `image/config/KyberDocker.yaml`:

```yaml
# image/config/KyberDocker.yaml
BENCH_NAME: "superyongzhe/bench"
BENCH_INITRC: "/etc/profile.d/init.sh"
BENCH_IMG_DISTRO: "ubuntu"
```

#### 3.2 Image-specific Configuration

Each image directory can create `KyberDocker.yaml` to override global configuration:

```yaml
# image/dockerfile/linaro/KyberDocker.yaml
LINARO_GCC_URL: https://releases.linaro.org/components/toolchain/binaries/7.3-2018.05/aarch64-linux-gnu/gcc-linaro-7.3.1-2018.05-x86_64_aarch64-linux-gnu.tar.xz
LINARO_GCC_PACKAGE_NAME: gcc-linaro-7.3.1-2018.05-x86_64_aarch64-linux-gnu.tar.xz
```

### 4. Variable Priority

Variables are merged with the following priority (later ones override earlier ones):

| Priority | Source | Description |
|----------|--------|-------------|
| 1 (lowest) | `-c` specified config file | YAML file specified via `-c` parameter |
| 2 | Global config `image/config/KyberDocker.yaml` | Global default configuration |
| 3 | Image directory `KyberDocker.yaml` | Configuration in current image directory |
| 4 | `-w` workdir `KyberDocker.yaml` | Configuration in work directory specified via `-w` |
| 5 (highest) | `-e` command line variables | Variables specified via `-e name=value` |

**Priority Diagram**:

```
┌─────────────────────────────────────────────────────────────┐
│  5. -e name=value           (Command line variables)        │
│      ↓ Overrides                                           │
│  4. -w workdir/KyberDocker.yaml                            │
│      ↓ Overrides                                           │
│  3. Image directory/KyberDocker.yaml                       │
│      ↓ Overrides                                           │
│  2. image/config/KyberDocker.yaml    (Global config)       │
│      ↓ Overrides                                           │
│  1. -c specified config file       (Lowest priority)       │
└─────────────────────────────────────────────────────────────┘
```

### 5. kyberdocker Command Usage

```bash
# Basic usage (using default configuration)
./kyberdocker

# Specify work directory
./kyberdocker -w /path/to/workdir

# Specify custom config file
./kyberdocker -c myconfig.yaml

# Specify template file
./kyberdocker -t Dockerfile.j2

# Specify output file
./kyberdocker -o output/Dockerfile

# Add command line variables (highest priority)
./kyberdocker -e BENCH_NAME=myrepo/bench -e DEBUG=true

# Complete example
./kyberdocker -w ./bench -c config.yaml -t Dockerfile.j2 -o Dockerfile -e VERSION=1.0
```

### 6. Command Line Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `-w` | Work directory | Current directory |
| `-c` | YAML config file path | `KyberDocker.yaml` |
| `-t` | Jinja2 template file path | `Dockerfile.j2` |
| `-o` | Output Dockerfile path | `Dockerfile` |
| `-e` | Custom variable (format: name=value) | None |

### 7. Practical Examples

#### Example 1: Build architecture-specific image

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

#### Example 2: Conditional dependency installation

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

#### Example 3: Override variables via command line

```bash
# Build with default configuration
./kyberdocker

# Use custom BENCH_NAME
./kyberdocker -e BENCH_NAME=myregistry/mybench

# Enable debug mode
./kyberdocker -e DEBUG=true -e LOG_LEVEL=verbose
```

### 8. Configuration File Search Order

When using `-w` parameter to specify work directory, configuration files are searched in:

1. Current command execution directory
2. Work directory specified by `-w`

Template files and output files follow the same resolution rules.

---

## Build Rules and Utilities

- **Environment Management**: Rules for setting up and configuring development environments
- **Container Orchestration**: Tools for managing Docker containers and images
- **Build Automation**: Macros for automating common build tasks
- **Configuration Management**: Flexible configuration system for different environments
- **Version Control**: Git integration for version tracking and management
- **Cross-compilation Support**: Tools for cross-compiling to different architectures

For more details, see the [rules documentation](rules/README.md).

## License

KyberBench adopts the Apache License 2.0 open source license. For specific terms, please refer to the [LICENSE](LICENSE) file.

## Contribution

Contributions and suggestions are welcome. Please ensure you follow the project's code style and contribution guidelines. Some ways to contribute include:

- Adding new containerized development environments
- Improving existing Docker configurations
- Extending build rules and utilities
- Writing documentation and examples
- Testing on different hardware platforms

---

**KyberBench**
Container-based Virtual Development Environment Builder
Copyright (c) 2025-2026, Kyber Development Team, all rights reserved.
