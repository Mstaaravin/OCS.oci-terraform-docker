#!/bin/bash

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

# Get system information
get_memory_info() {
    free -h | awk '/^Mem:/ {print $2}'
}

get_disk_info() {
    df -h / | awk 'NR==2 {print $2}'
}

# Print welcome banner
print_line
print_centered "Development Container"
print_line

# Environment Information Section
echo -e "\nEnvironment Configuration:"
echo "  - Region: $TF_VAR_region"
echo "  - Tenancy: $TF_VAR_tenancy_ocid"

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

# print_line
#echo -e "\nContainer is ready for use.\n"

# Execute the command passed to docker run (or bash by default)
# The exec command replaces the current process with the specified command,
# ensuring proper signal handling and process management
exec "$@"
