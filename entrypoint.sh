#!/bin/bash
set -e

# Function to print a horizontal line
print_line() {
    echo "================================================"
}

# Function to print centered text
print_centered() {
    local text="$1"
    local width=48  # Width of our banner
    local padding=$(( (width - ${#text}) / 2 ))
    printf "%${padding}s%s%${padding}s\n" "" "$text" ""
}

# Handle dynamic UID/GID changes
if [ "$(id -u)" = "0" ]; then
    # Get the PUID/PGID from environment variables
    PUID=${PUID:-1000}
    PGID=${PGID:-1000}
    # USER_NAME=${USER_NAME:-containeruser}
    # USER_NAME=${USER_NAME:-${USER}}
    USER_NAME=${USER_NAME:-$(getent passwd $(stat -c %u /proc/1) | cut -d: -f1 || echo "containeruser")}

    echo "Setting up user ${USER_NAME} with UID:GID ${PUID}:${PGID}"

    # Check if UID already exists but is assigned to a different user
    EXISTING_USER=$(getent passwd ${PUID} | cut -d: -f1 || echo "")
    if [ -n "$EXISTING_USER" ] && [ "$EXISTING_USER" != "$USER_NAME" ]; then
        echo "UID ${PUID} is already assigned to user ${EXISTING_USER}. Moving to temporary UID."
        usermod -u 9999 ${EXISTING_USER}
        echo "Moved ${EXISTING_USER} to UID 9999 temporarily"
    fi

    # Create/modify group
    if ! getent group ${PGID} > /dev/null 2>&1; then
        echo "Creating group with GID: ${PGID}"
        groupadd -g ${PGID} ${USER_NAME}
    elif [ "$(getent group ${PGID} | cut -d: -f1)" != "${USER_NAME}" ]; then
        echo "Group with GID ${PGID} already exists, using it"
    fi

    # Check if user exists
    if id -u ${USER_NAME} > /dev/null 2>&1; then
        echo "User ${USER_NAME} already exists, updating UID/GID"
        usermod -u ${PUID} -g ${PGID} -d /home/${USER_NAME} ${USER_NAME} || true
    else
        echo "Creating user ${USER_NAME} with UID: ${PUID}"
        useradd -u ${PUID} -g ${PGID} -s /bin/bash -m -d /home/${USER_NAME} ${USER_NAME} || true

        # If useradd fails, try a different approach
        if ! id -u ${USER_NAME} > /dev/null 2>&1; then
            echo "Standard useradd failed. Trying alternate approach."
            # First create without specific UID/GID
            useradd -s /bin/bash -m -d /home/${USER_NAME} ${USER_NAME} || true
            # Then modify to the desired UID/GID
            usermod -u ${PUID} -g ${PGID} ${USER_NAME} || true
        fi
    fi

    # Verify user creation
    if ! id -u ${USER_NAME} > /dev/null 2>&1; then
        echo "WARNING: Failed to create user ${USER_NAME}. Falling back to existing user."
        # Find an existing user to use
        FALLBACK_USER=$(getent passwd | grep -v "nologin\|false" | grep -v "^root:" | head -1 | cut -d: -f1)
        if [ -n "$FALLBACK_USER" ]; then
            echo "Using fallback user: ${FALLBACK_USER}"
            USER_NAME=${FALLBACK_USER}
        else
            echo "No suitable fallback user found. Using root."
            USER_NAME=root
        fi
    fi

    # Ensure home directory exists with correct permissions
    if [ "${USER_NAME}" != "root" ]; then
        mkdir -p /home/${USER_NAME}
        echo "Setting ownership of /home/${USER_NAME} to $(id -u ${USER_NAME}):$(id -g ${USER_NAME})"
        chown -R $(id -u ${USER_NAME}):$(id -g ${USER_NAME}) /home/${USER_NAME}

        # Create standard directories
        for dir in .oci .ssh .config; do
            mkdir -p /home/${USER_NAME}/${dir}
            chown $(id -u ${USER_NAME}):$(id -g ${USER_NAME}) /home/${USER_NAME}/${dir}
        done
    fi

    # Display banner before switching user
    print_line
    print_centered "OCI Terraform Development Container"
    print_line

    echo -e "\nEnvironment Configuration:"
    echo "  - User: ${USER_NAME} (UID: $(id -u ${USER_NAME}), GID: $(id -g ${USER_NAME}))"
    if [ -n "$TF_VAR_region" ]; then
        echo "  - Region: $TF_VAR_region"
    fi
    if [ -n "$TF_VAR_tenancy_ocid" ]; then
        echo "  - Tenancy: $TF_VAR_tenancy_ocid"
    fi

    echo -e "\nInstalled Tools:"
    echo "  - Terraform: $(terraform version | head -n1)"
    echo "  - Python: $(python3 --version)"
    echo "  - OCI CLI: $(oci --version)"

    echo -e "\nUseful Commands:"
    echo "  - 'terraform init' - Initialize Terraform working directory"
    echo "  - 'oci --help' - Show OCI CLI help"
    echo "  - 'exit' - Exit container"

    print_line
    echo -e "\nContainer is ready for use.\n"

    # Set up user environment
    if [ "${USER_NAME}" != "root" ]; then
        export HOME=/home/${USER_NAME}
    else
        export HOME=/root
    fi
    cd ${HOME}

    # Switch to the user and execute the command
    echo "Switching to user ${USER_NAME} ($(id -u ${USER_NAME}):$(id -g ${USER_NAME}))"
    if [ "${USER_NAME}" = "root" ]; then
        exec "$@"
    else
        exec gosu ${USER_NAME} "$@"
    fi

else
    # We're already running as a non-root user, just execute the command
    # Get system information
    get_memory_info() {
        free -h | awk '/^Mem:/ {print $2}'
    }

    get_disk_info() {
        df -h / | awk 'NR==2 {print $2}'
    }

    # Print welcome banner
    print_line
    print_centered "OCI Terraform Development Container"
    print_line

    # Environment Information Section
    echo -e "\nEnvironment Configuration:"
    echo "  - User: $(id -un) (UID: $(id -u), GID: $(id -g))"
    if [ -n "$TF_VAR_region" ]; then
        echo "  - Region: $TF_VAR_region"
    fi
    if [ -n "$TF_VAR_tenancy_ocid" ]; then
        echo "  - Tenancy: $TF_VAR_tenancy_ocid"
    fi

    # Tools & Versions Section
    echo -e "\nInstalled Tools:"
    echo "  - Terraform: $(terraform version | head -n1)"
    echo "  - Python: $(python3 --version)"
    echo "  - OCI CLI: $(oci --version)"

    # Tips Section
    echo -e "\nUseful Commands:"
    echo "  - 'terraform init' - Initialize Terraform working directory"
    echo "  - 'oci --help' - Show OCI CLI help"
    echo "  - 'exit' - Exit container"

    print_line
    echo -e "\nContainer is ready for use.\n"

    # Execute the command
    exec "$@"
fi
