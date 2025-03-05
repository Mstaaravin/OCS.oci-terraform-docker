################################################################################
# Dockerfile for OCI Terraform Development Environment
################################################################################
# Author: [Marvin] Carlos Miranda Molina
# Created: February 2025
# Last Modified: March 05, 2025
#
# Description: 
# This Dockerfile builds a development environment for Oracle Cloud Infrastructure
# using Terraform and OCI CLI. It's based on Oracle Linux 9 slim and
# includes essential development tools.
#
# Key Components:
# - Base Image: oraclelinux:9-slim
# - Terraform (latest version)
# - Python 3.11 with OCI CLI 3.52
# - Development tools: git, jq, nano, vim
# - User configuration with dynamic UID/GID mapping
# - Security-focused configuration with non-root user
#
# Usage:
# Build with: docker build --build-arg USER_NAME=$(whoami) \
#                         --build-arg USER_UID=$(id -u) \
#                         --build-arg USER_GID=$(id -g) \
#                         -f Dockerfile9 \
#                         -t ocs-oci-terraform-ol:latest .
################################################################################

# Use Oracle Linux 9 slim as base
FROM oraclelinux:9-slim

# User configuration arguments
ARG USER_NAME
ARG USER_UID
ARG USER_GID

# Set OCI CLI version for reproducible builds
ARG OCI_CLI_VERSION=3.52
# Set Terraform version for reproducible builds
ARG TERRAFORM_VERSION=1.11.0
# Set Python version
ARG PYTHON_VERSION=3.12

# Configure environment variables
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PATH="/opt/venv/bin:/usr/local/bin:$PATH" \
    OCI_CLI_VERSION=${OCI_CLI_VERSION} \
    TERRAFORM_VERSION=${TERRAFORM_VERSION} \
    PYTHON_VERSION=${PYTHON_VERSION}

# Install basic required packages
RUN microdnf update -y && \
    microdnf install -y \
        dnf \
        python3 \
        unzip \
        tar \
        gzip \
        curl \
        wget \
        git \
        jq \
        nano \
        vim \
        findutils \
        procps \
        bash \
        bash-completion \
        shadow-utils \
        which && \
    microdnf clean all

# Install Python 3.11 from Oracle's CodeReady Builder repo
RUN dnf install -y dnf-plugins-core oraclelinux-release-el9 && \
    dnf config-manager --set-enabled ol9_codeready_builder && \
    dnf install -y \
        python${PYTHON_VERSION} \
        python${PYTHON_VERSION}-pip \
        python${PYTHON_VERSION}-devel && \
    # Create symlinks to make python3 use the specified version
    ln -sf /usr/bin/python${PYTHON_VERSION} /usr/bin/python3 && \
    ln -sf /usr/bin/pip${PYTHON_VERSION} /usr/bin/pip3 && \
    dnf clean all

# Set up Python virtual environment for OCI CLI
RUN python3 -m venv /opt/venv && \
    /opt/venv/bin/pip install --no-cache-dir --upgrade pip && \
    /opt/venv/bin/pip install --no-cache-dir "oci-cli==${OCI_CLI_VERSION}" && \
    echo "Python version:" && python3 --version && \
    echo "OCI CLI version:" && oci --version

# Download and install Terraform
RUN curl -fsSL https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip -o terraform.zip && \
    unzip terraform.zip -d /usr/local/bin && \
    rm terraform.zip && \
    chmod +x /usr/local/bin/terraform && \
    echo "Terraform version:" && terraform version

# Create non-root user if necessary
RUN if [ "${USER_UID:-0}" != "0" ]; then \
        groupadd -g ${USER_GID} ${USER_NAME} 2>/dev/null || true && \
        useradd -u ${USER_UID} -g ${USER_GID} -m -s /bin/bash ${USER_NAME} 2>/dev/null || true; \
    elif [ "${USER_NAME}" != "root" ]; then \
        ln -s /root /home/${USER_NAME}; \
    fi

# Create necessary directories for the user
RUN mkdir -p /home/${USER_NAME}/.oci && \
    mkdir -p /home/${USER_NAME}/.ssh && \
    touch /home/${USER_NAME}/.bash_history && \
    if [ "${USER_UID:-0}" != "0" ]; then \
        chown -R ${USER_NAME}:${USER_NAME} /home/${USER_NAME}; \
    fi

# Configure entrypoint
COPY entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/entrypoint.sh && \
    if [ "${USER_UID:-0}" != "0" ]; then \
        chown ${USER_NAME}:${USER_NAME} /usr/local/bin/entrypoint.sh; \
    fi

# Set bash as default shell
SHELL ["/bin/bash", "-c"]

# Configure working directory
WORKDIR /home/${USER_NAME}

# Switch to non-root user
USER ${USER_NAME}

# Set entrypoint and default command
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["bash"]