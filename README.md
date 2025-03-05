# OCS OCI Terraform Docker Toolkit

A comprehensive containerized toolkit for Oracle Cloud Infrastructure (OCI) development using Terraform.

Need help? Check out our detailed [FAQ](FAQ.md) for common questions and solutions.

## Overview

This toolkit provides a pre-configured Docker environment that bundles essential tools and utilities for OCI infrastructure development. It's designed for seamless integration with Terraform workflows and OCI management tasks. It maintains bash history and persistence, includes a basic ~/.bashrc configuration with colorized $PS1, and integrates easy git branch identification for quick workspace recognition.

>**This container image is essentially the OCI Cloud Shell experience brought to your own machine.** It provides **almost** the same tools, utilities, and workflow capabilities as the OCI console's Cloud Shell, but with the advantages of persistence, customization, and local access.

## Table of Contents
- [Overview](#overview)
- [Key Features](#key-features)
  - [Permission Management](#permission-management)
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

- Automated user permission mapping from host to container (UID/GID)
- Dynamic user creation matching host credentials
- Pre-installed and configured development tools (nano, vim, rsync, etc)
- Integrated OCI and Terraform workflows
- Secure credential management
- User-friendly entrypoint with system information
- Persistence Features inside container
- Command history across sessions
- Shell configurations and aliases
- WSL support ([tested on Oracle Linux 8.x](doc/img/wsl.png))

### Permission Management

The toolkit automatically detects and uses your local user's UID and GID when building the image and creating containers. This means:
- No permission conflicts between host and container
- Files created in the container match your host user permissions
- Seamless access to mounted volumes
- Secure non-root execution

## Base Image

The toolkit uses Oracle Linux 9 Slim as its base, providing compatibility with OCI Cloud Shell environment:

- Uses `oraclelinux:9-slim` as the foundation
- Oracle Linux compatibility for consistent OCI experience
- Pre-installed Terraform (version 1.7.5)
- Dockerfile: `Dockerfile9`

To build the image:
```bash
docker build -f Dockerfile9 \
  --build-arg USER_NAME=$(whoami) \
  --build-arg USER_UID=$(id -u) \
  --build-arg USER_GID=$(id -g) \
  -t ocs-oci-terraform:latest .
```

The docker-compose.yml file is configured to use this image:
```yaml
services:
  container03:
    image: ocs-oci-terraform:3.51.8
    build:
      context: .
      dockerfile: Dockerfile9
      args:
        USER_NAME: ${USER}
        USER_UID: ${UID:-1000}
        USER_GID: ${GID:-1000}
        OCI_CLI_VERSION: ${OCI_CLI_VERSION:-3.51.8}
```

## Included Tools

### Base Image
- Oracle Linux 9 Slim
  - Enterprise-grade base OS
  - Direct compatibility with OCI Cloud Shell
  - Oracle-optimized environment
  - Explicit Terraform installation (version 1.7.5)

### Core Components
- Terraform
  - Latest version from hashicorp/terraform (in Alpine variant)
  - Version 1.7.5 (in Oracle Linux variant)
- OCI CLI 3.51.6
- Python 3.x

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
When changing OCI CLI version, only the installation layer will be rebuilt while maintaining other cached layers:
```bash
docker build \
  -f Dockerfile.hashicorp \  # or Dockerfile.oracle
  --build-arg USER_NAME=$(whoami) \
  --build-arg USER_UID=$(id -u) \
  --build-arg USER_GID=$(id -g) \
  --build-arg OCI_CLI_VERSION=<new_version> \
  -t ocs-oci-terraform:<base>-<new_version>
  ```

## Quick Start

1. **Verify Configuration**
   - Check that the `docker-compose.yml` file is using the Dockerfile9
   - Make sure your environment is ready for Oracle Linux 9 based image

2. **Generate Required Credentials**
   - Generate SSH keys: [OCI SSH Key Generation Guide](https://docs.oracle.com/en-us/iaas/Content/GSG/Tasks/creatingkeys.htm)
   ```bash
   # [HOST] Generate SSH key pair
   ssh-keygen -t rsa -b 4096 -f ${HOME}/Projects/customer01/.ssh/id_rsa
   ```
   
   - Generate OCI API keys: [OCI API Signing Key Guide](https://docs.oracle.com/en-us/iaas/Content/API/Concepts/apisigningkey.htm)
   ```bash
   # [HOST] Generate OCI API key pair
   openssl genrsa -out ${HOME}/Projects/customer01/.oci/oci_api_key.pem 4096
   openssl rsa -pubout -in ${HOME}/Projects/customer01/.oci/oci_api_key.pem -out ${HOME}/Projects/customer01/.oci/oci_api_key_public.pem
   ```

3. **Prepare Directory Structure**
   ```bash
   # [HOST] Create required directory structure
   mkdir -p ${HOME}/Projects/customer01/{.oci,.ssh}
   
   # [HOST] Create required files
   touch ${HOME}/Projects/customer01/.bashrc
   touch ${HOME}/Projects/customer01/.bash_history
   ```
   Note: We use ${HOME}/Projects/customer01 as an example path in the docker host that will be mounted as ~/ in the container.

4. **Configure Environment**
   ```bash
   # [HOST] Copy .env file before start container
   cp .env.example .env
   # Edit .env with your OCI credentials
   ```

5. **Launch Toolkit**
   ```bash
   docker compose up -d
   ```
   The first time you run this command, it will build the image automatically. 
   Subsequent runs will reuse the existing image unless you explicitly rebuild it.

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

## Security Features

- Non-root user execution
- Host-mounted credentials
- Secure volume management
- Environment-based configuration

## Container Structure

```plaintext
.
├── doc                    # Some documentation files and images
├── .bashrc                # .bashrc example for use inside container
├── Dockerfile9            # Oracle Linux 9 image definition  
├── docker-compose.yml     # Container orchestration
├── entrypoint.sh          # Initialization script
├── .env.example           # Environment template
└── README.md              # Documentation
```

## Container Information

When the container starts, the entrypoint script displays comprehensive information including:
- Environment Configuration
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