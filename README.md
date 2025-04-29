# OCS OCI Terraform Docker Toolkit

A comprehensive containerized toolkit for Oracle Cloud Infrastructure (OCI) development using Terraform.

Need help? Check out our detailed [FAQ](FAQ.md) for common questions and solutions.

## Overview

This toolkit provides a pre-configured Docker environment that bundles essential tools and utilities for OCI infrastructure development. **Its primary purpose is to isolate multiple OCI tenancies/accounts with separate configurations, credentials, and workspaces** - each container represents a distinct OCI environment, eliminating accidental cross-tenancy operations.

Key benefits:
- **Tenant isolation**: Each container maintains its own OCI credentials and configurations
- **Clean separation**: No more switching between config files or profiles for different tenancies
- **Simplified management**: Each project directory represents a distinct OCI environment

The toolkit maintains bash history and persistence, includes a basic ~/.bashrc configuration with colorized $PS1, and integrates easy git branch identification for quick workspace recognition.

>**This container image is essentially the OCI Cloud Shell experience brought to your own machine.** It provides **almost** the same tools, utilities, and workflow capabilities as the OCI console's Cloud Shell, but with the advantages of persistence, customization, local access, and most importantly, **complete isolation between different OCI tenancies**.

## Table of Contents
- [Overview](#overview)
- [Key Features](#key-features)
  - [Permission Management](#permission-management)
  - [Registry Compatibility](#registry-compatibility)
- [Image Options](#image-options)
- [Included Tools](#included-tools)
  - [Base Images](#base-images)
  - [Core Components](#core-components)
  - [Development Utilities](#development-utilities)
- [Requirements](#requirements)
- [Build Performance](#build-performance)
- [Quick Start](#quick-start)
- [Multi-tenant Support](#multi-tenant-support)
- [Configuration](#configuration)
- [Security Features](#security-features)
- [Container Structure](#container-structure)
- [Container Information](#container-information)
- [Usage Examples](#usage-examples)
- [Contributing](#contributing)

## Key Features

- **Dynamic UID/GID mapping** for host-container permission synchronization
- Pre-installed and configured development tools (nano, vim, rsync, etc)
- Integrated OCI and Terraform workflows
- Secure credential management
- User-friendly entrypoint with system information
- Persistence Features inside container
- Command history across sessions
- Shell configurations and aliases
- WSL support ([tested on Oracle Linux 8.x](doc/img/wsl.png))

### Permission Management

The toolkit provides two layers of user permission management:

1. **Build-time UID/GID mapping**:
   - During image build, uses your local user's UID and GID
   - Creates a user in the container that matches your host user

2. **Runtime UID/GID mapping**:
   - When running a pre-built image (from a registry), dynamically adjusts to the current user
   - Uses environment variables PUID and PGID to match container user with host user
   - Implemented with gosu for proper privilege de-escalation

This dual approach means:
- No permission conflicts between host and container
- Files created in the container match your host user permissions
- Seamless access to mounted volumes
- Secure non-root execution
- **Registry-friendly images** that work across different systems

### Registry Compatibility

A key improvement in this toolkit is the ability to share images via registries without permission problems:

- Images built locally can be pushed to a registry
- Other users can pull and run these images with their own UID/GID
- No need to rebuild images for different users
- Container automatically adapts to the host user at runtime

## Base Image

The toolkit uses Oracle Linux 9 Slim as its base, providing compatibility with OCI Cloud Shell environment:

- Uses `oraclelinux:9-slim` as the foundation
- Oracle Linux compatibility for consistent OCI experience
- Pre-installed Terraform (version 1.11.4)
- Dockerfile: `Dockerfile`

To build the image:
```bash
docker build -f Dockerfile \
  --build-arg USER_NAME=$(whoami) \
  --build-arg USER_UID=$(id -u) \
  --build-arg USER_GID=$(id -g) \
  -t ocs-oci-terraform:latest .
```

The docker-compose.yml file is configured to use this image:
```yaml
services:
  container03:
    image: ocs-oci-terraform:latest
    build:
      context: .
      dockerfile: Dockerfile
      args:
        USER_NAME: ${USER}
        USER_UID: ${UID:-1000}
        USER_GID: ${GID:-1000}
        OCI_CLI_VERSION: ${OCI_CLI_VERSION:-3.54.4}
        TERRAFORM_VERSION: ${TERRAFORM_VERSION:-1.11.4}
        PYTHON_VERSION: ${PYTHON_VERSION:-3.12}
    environment:
      - PUID=${UID:-1000}
      - PGID=${GID:-1000}
      - USER_NAME=${USER}
```

## Included Tools

### Base Image
- Oracle Linux 9 Slim
  - Enterprise-grade base OS
  - Direct compatibility with OCI Cloud Shell
  - Oracle-optimized environment
  - Explicit Terraform installation (version 1.11.4)

### Core Components
- Terraform
  - Version 1.11.4 (in Oracle Linux variant)
- OCI CLI 3.54.4
- Python 3.12.5
- gosu 1.16 (for secure user switching)

### Development Utilities
- Git for version control
- jq for JSON processing
- nano and vim editors
- bash with completion

## Requirements

1. **WSL Configuration**
   - Windows Subsystem for Linux (WSL) installed and properly configured on your Windows system
   - WSL2 is recommended for better performance and compatibility

2. **Linux Distribution Setup**
   - Any Linux distribution installed in WSL
   - Docker installed and configured as a systemd service
   - Systemd must be enabled in WSL (See [WSL Systemd Setup Guide](https://learn.microsoft.com/en-us/windows/wsl/systemd))
   ```bash
   # Verify systemd is running
   systemctl status
   ```

3. **User Configuration**
   - Default root user is sufficient
   - Any other user with sudo privileges works as well
   - No specific user requirements needed

4. **Directory Structure**
   - Create project directories inside WSL for different tenancies:
   ```bash
   # Create base directory structure
   mkdir -p ~/Projects/{customer01,customer02,customer03}
   ```

## Build Performance & Behavior

The Dockerfiles are optimized for build performance using efficient layer caching:

### Build Times
- Initial build: ~80-90 seconds
  * Downloads and installs all required dependencies
  * Creates Python virtual environment
  * Installs OCI CLI and its dependencies

- Subsequent builds: <1 second
  * Uses cached layers
  * Only rebuilds modified layers
  * Maintains all other cached components

### Version Changes
You can customize tool versions through build arguments:
```bash
docker build \
  -f Dockerfile \
  --build-arg USER_NAME=$(whoami) \
  --build-arg USER_UID=$(id -u) \
  --build-arg USER_GID=$(id -g) \
  --build-arg OCI_CLI_VERSION=3.54.4 \
  --build-arg TERRAFORM_VERSION=1.11.4 \
  --build-arg PYTHON_VERSION=3.12 \
  -t ocs-oci-terraform:latest
```

## Quick Start

### Option 1: Build and Run Locally

1. **Prepare Directory Structure**
   ```bash
   # [HOST] Create required directory structure
   mkdir -p ${HOME}/Projects/customer01/{.oci,.ssh}
   
   # [HOST] Create required files
   touch ${HOME}/Projects/customer01/.bashrc
   touch ${HOME}/Projects/customer01/.bash_history
   ```

2. **Configure Environment**
   ```bash
   # [HOST] Copy .env file before start container
   cp .env.example .env
   # Edit .env with your OCI credentials
   ```

3. **Build and Launch Toolkit**
   ```bash
   # Build the image and start container
   docker compose build
   docker compose up -d
   
   # Or in one command:
   docker compose up -d --build
   ```

### Option 2: Use from Registry

1. **Pull Image from Registry**
   ```bash
   # Modify docker-compose.yml to point to your registry
   # Then pull the image
   docker compose pull
   ```

2. **Run with Local User Permissions**
   ```bash
   # The container will automatically use your UID/GID
   docker compose up -d
   ```

## Multi-tenant Support

The toolkit is designed to support multiple OCI tenancies/customers. The docker-compose.yml uses a configurable host path (default: ${HOME}/Projects/customer01) where you can store tenant-specific configurations:

```plaintext
~/Projects/customer01/
├── .oci/              # OCI configuration files
├── .ssh/              # SSH keys
├── .bashrc            # Bash configuration
├── .bash_history      # Command history
└── git.terraform01/     # Terraform configurations

~/Projects/tenancy02/
├── .oci/              # OCI configuration files
├── .ssh/              # SSH keys
├── .bashrc            # Bash configuration
├── .bash_history      # Command history
└── git.external_repository/     # Terraform configurations
```

You can create similar directories for different customers and modify the volume mounts in docker-compose.yml accordingly. This structure allows you to:
- Maintain separate credentials per customer
- Keep isolated configurations
- Switch between different tenancies easily

## Configuration

### Required Environment Variables
- `TF_VAR_tenancy_ocid`: OCI tenancy OCID
- `TF_VAR_user_ocid`: OCI user OCID
- `TF_VAR_fingerprint`: API key fingerprint

### Optional Environment Variables
- `TF_VAR_region`: Override default region
- `TF_VAR_private_key_path`: Custom private key path
- `PUID`: User ID for container (defaults to current user's UID)
- `PGID`: Group ID for container (defaults to current user's GID)

## Security Features

- Non-root user execution
- Dynamic user mapping via gosu
- Host-mounted credentials
- Secure volume management
- Environment-based configuration

## Container Structure

```plaintext
.
├── doc                    # Some documentation files and images
├── .bashrc                # .bashrc example for use inside container
├── Dockerfile             # Oracle Linux 9 image definition  
├── docker-compose.yml     # Container orchestration
├── entrypoint.sh          # Initialization script with dynamic UID/GID mapping
├── .env.example           # Environment template
└── README.md              # Documentation
```

## Container Information

When the container starts, the entrypoint script displays comprehensive information including:
- Environment Configuration
- User details (UID/GID)
- Region and Tenancy details
- Installed Tools Versions
- Terraform version
- Python version
- OCI CLI version
- Useful Commands

## Usage Examples

Access the toolkit environment:
```bash
docker exec -it container03 bash
```

Common operations:
```bash
terraform init
terraform plan
oci --help
```

## Contributing

Please refer to project maintainers for contribution guidelines.
