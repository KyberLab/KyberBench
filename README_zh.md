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

- **kyberdocker**：用于支持Dockerfile Jinja2模板的脚本
- **kyberinstall**：用于根据dockpin的apt lock文件安装软件包和管理依赖的脚本

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
