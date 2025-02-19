################################################################################
# Dockerfile for OCI Terraform Development Environment
################################################################################
# Author: [Marvin] Carlos Miranda Molina
# Created: February 2025
# Last Modified: February 9, 2025
#
# Description: 
# This Dockerfile builds a development environment for Oracle Cloud Infrastructure
# using Terraform and OCI CLI. It's based on the official Terraform image and
# includes essential development tools.
#
# Key Components:
# - Base Image: hashicorp/terraform:latest
# - Python 3.x with OCI CLI 3.51.6
# - Development tools: git, jq, nano, vim
# - User configuration with dynamic UID/GID mapping
# - Security-focused configuration with non-root user
#
# Usage:
# Build with: docker build --build-arg USER_NAME=$(whoami) \
#                         --build-arg USER_UID=$(id -u) \
#                         --build-arg USER_GID=$(id -g) \
#                         -t ocs-oci-terraform:latest .
################################################################################

# Use the latest official Terraform image as base
FROM hashicorp/terraform:latest

# User configuration arguments
ARG USER_NAME
ARG USER_UID
ARG USER_GID

# Set OCI CLI version for reproducible builds
ARG OCI_CLI_VERSION=3.51.6

# Configure Python environment
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PATH="/opt/venv/bin:$PATH" \
    TERRAFORM_VERSION=${TERRAFORM_VERSION} \
    OCI_CLI_VERSION=${OCI_CLI_VERSION}

# Create non-root user if necessary
RUN if [ "${USER_UID:-0}" != "0" ]; then \
        addgroup -g ${USER_GID} ${USER_NAME} 2>/dev/null || true && \
        adduser -D -u ${USER_UID} -G ${USER_NAME} ${USER_NAME} 2>/dev/null || true && \
        # Create /etc/passwd entry for WSL compatibility
        echo "${USER_NAME}:x:${USER_UID}:${USER_GID}:${USER_NAME}:/home/${USER_NAME}:/bin/bash" >> /etc/passwd && \
        echo "${USER_NAME}:x:${USER_GID}:" >> /etc/group; \
    elif [ "${USER_NAME}" != "root" ]; then \
        ln -s /root /home/${USER_NAME}; \
    fi

# Install Python and OCI CLI dependencies
RUN \
    apk update && \
    apk add --no-cache \
        python3 \
        py3-pip \
        python3-dev \
        gcc \
        musl-dev \
        libffi-dev \
        openssl-dev \
        cargo && \
    python3 -m venv /opt/venv && \
    pip3 install --no-cache-dir "oci-cli==${OCI_CLI_VERSION}" && \
    echo "Python version:" && python3 --version && \
    echo "OCI CLI version:" && oci --version

# Install development tools and configure environment
RUN \
    apk add --no-cache \
        bash \
        bash-completion \
        git \
        curl \
        procps \
        jq \
        nano \
        vim && \
    rm -rf /root/.cache/* && \
    apk del gcc musl-dev python3-dev libffi-dev openssl-dev cargo && \
    mkdir -p /home/${USER_NAME}/.oci && \
    mkdir -p /home/${USER_NAME}/.ssh && \
    touch /home/${USER_NAME}/.bash_history && \
    if [ "${USER_UID:-0}" != "0" ]; then \
        chown -R ${USER_NAME}:${USER_NAME} /home/${USER_NAME} && \
        chown -R ${USER_NAME}:${USER_NAME} /opt/venv; \
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