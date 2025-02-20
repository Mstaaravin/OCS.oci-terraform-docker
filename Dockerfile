################################################################################
# Stage 1: Builder for OCI CLI
FROM python:3.12-alpine AS builder

# Set OCI CLI version for reproducible builds
ARG OCI_CLI_VERSION=3.51.6

# Create and populate virtual environment
RUN python -m venv /opt/venv && \
    /opt/venv/bin/pip install --no-cache-dir "oci-cli==${OCI_CLI_VERSION}"

################################################################################
# Stage 2: Final image
FROM hashicorp/terraform:latest

# User configuration arguments
ARG USER_NAME
ARG USER_UID
ARG USER_GID

# Configure Python environment
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PATH="/opt/venv/bin:$PATH"

# Create non-root user if necessary
RUN if [ "${USER_UID:-0}" != "0" ]; then \
        addgroup -g ${USER_GID} ${USER_NAME} 2>/dev/null || true && \
        adduser -D -u ${USER_UID} -G ${USER_NAME} ${USER_NAME} 2>/dev/null || true && \
        echo "${USER_NAME}:x:${USER_UID}:${USER_GID}:${USER_NAME}:/home/${USER_NAME}:/bin/bash" >> /etc/passwd && \
        echo "${USER_NAME}:x:${USER_GID}:" >> /etc/group; \
    elif [ "${USER_NAME}" != "root" ]; then \
        ln -s /root /home/${USER_NAME}; \
    fi

# Install basic system tools and Python
RUN apk add --no-cache \
        python3 \
        bash \
        bash-completion \
        git \
        curl \
        procps \
        jq \
        nano \
        vim

# Copy virtual environment from builder
COPY --from=builder /opt/venv /opt/venv

# Create and set permissions for home directory structure
RUN mkdir -p /home/${USER_NAME}/.oci /home/${USER_NAME}/.ssh && \
    touch /home/${USER_NAME}/.bash_history && \
    if [ "${USER_UID:-0}" != "0" ]; then \
        chown ${USER_NAME}:${USER_NAME} \
            /home/${USER_NAME} \
            /home/${USER_NAME}/.oci \
            /home/${USER_NAME}/.ssh \
            /home/${USER_NAME}/.bash_history; \
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