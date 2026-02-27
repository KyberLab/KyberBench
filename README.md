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
