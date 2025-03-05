# Frequently Asked Questions (FAQ)

## Table of Contents
- [Image Selection](#image-selection)
  - [Which base image should I choose?](#q-which-base-image-should-i-choose)
  - [How to switch between images?](#q-how-do-i-switch-between-the-hashicorp-terraform-and-oracle-linux-images)
  - [Version differences](#q-what-are-the-version-differences-between-the-two-images)
- [Container Setup](#container-setup)
  - [User not found when starting container](#q-why-cant-docker-find-my-user-when-starting-the-container)
  - [Recreating container after .bashrc modifications](#q-do-i-need-to-recreate-the-container-after-modifying-my-bashrc)
  - [Multiple OCI configurations](#q-can-i-use-different-oci-configurations-for-different-projects)
- [Credentials](#credentials)
  - [How do I get my OCI credentials?](#q-how-do-i-get-my-oci-credentials)
  - [Updating OCI credentials](#q-how-do-i-update-my-oci-credentials)
  - [Credential security](#q-are-my-credentials-secure-in-the-container)
  - [Check connectivity against OCI Tenancy?](#q-how-i-can-check-connectivity-and-auth-against-oci-tenancy)
  - ["No such file or directory" Error when use oci cli?](#q-why-i-got-no-such-file-or-directory-when-use-oci-cli)
- [Development](#development)
  - [Installing additional tools](#q-can-i-install-additional-tools-in-the-container)
  - [Updating versions](#q-how-do-i-update-terraformoci-cli-versions)
- [Troubleshooting](#troubleshooting)
  - [Permission errors](#q-container-fails-to-start-with-permission-errors)
  - [Code changes not reflected](#q-changes-to-my-code-arent-reflected-in-the-container)
- [Performance](#performance)
  - [WSL impact](#q-is-there-a-performance-impact-using-wsl)
  - [Memory consumption](#q-will-the-container-consume-too-much-memory)

## Image Selection

### Q: Which base image should I choose?
**A:** Choose based on your specific needs:
- **HashiCorp Terraform Alpine** (`Dockerfile.hashicorp`): Smaller, lighter container based on Alpine Linux. Best for most development scenarios where minimal resource usage is important.
- **Oracle Linux 9 Slim** (`Dockerfile.oracle`): Better compatibility with Oracle environments. Choose this if you're working extensively with Oracle products or need specific Oracle Linux packages.

### Q: How do I switch between the HashiCorp Terraform and Oracle Linux images?
**A:** You can switch by modifying your docker-compose.yml file:

```yaml
services:
  container03:
    build:
      context: .
      dockerfile: Dockerfile.hashicorp  # Change to Dockerfile.oracle for Oracle Linux
```

Then rebuild and restart:
```bash
docker compose down
docker compose up -d --build
```

### Q: What are the version differences between the two images?
**A:** The main differences are:
- **HashiCorp Terraform Alpine**: Uses the latest Terraform version from HashiCorp's official image
- **Oracle Linux 9 Slim**: Explicitly installs Terraform 1.7.5 (this version can be changed via the `TERRAFORM_VERSION` build arg)

Both images use the same OCI CLI version as specified in the build arguments.

## Container Setup

### Q: Why can't Docker find my user when starting the container?
**A:** This usually happens in WSL environments. Ensure your user exists in the container by rebuilding with:
```bash
docker compose build --no-cache
docker compose up -d
```

### Q: Do I need to recreate the container after modifying my .bashrc?
**A:** No. Changes to mounted files (including .bashrc) are immediately available in the container.

### Q: Can I use different OCI configurations for different projects?
**A:** Yes. Create separate directories under ${HOME}/Projects/ for each project/customer and modify the volume mounts in docker-compose.yml accordingly.

## Credentials

### Q: How do I get my OCI credentials?
**A:** Inside OCI Console go to Your Profile -> API Keys ([Screenshot api_key.png](doc/img/api_key.png))<br />
**A:** Generate and get your private keys ([Screenshot add_api_key_files.png](doc/img/add_api_key_files.png))<br />
**A:** get yout configuration file preview and put it in in your ${HOME}/Projects/customer01/.oci/config ([Screenshot api_key_configuration_preview.png](doc/img/api_key_configuration_preview.png))<br />
**A:** Like this:
```bash
cmiranda@tenancyName ~$ cat .oci/config 
[DEFAULT]
user=ocid1.user.oc1..aaa############flhogymalaj76cwq
fingerprint=xx:xx:xx:xx:xx:xx:xx:xx:xx:xx
tenancy=ocid1.tenancy.oc1..aaaaaa########################6h6lape
region=sa-saopaulo-1
key_file=/home/cmiranda/.oci/tenancyName.pem
```

### Q: How do I update my OCI credentials?
**A:** Update files in your ${HOME}/Projects/customer01/.oci directory. The container will use the updated credentials immediately.

### Q: Are my credentials secure in the container?
**A:** Yes. Credentials are mounted as volumes and never copied into the container image.

### Q: How I can check connectivity and auth against OCI Tenancy?
**A:** 1. Put you aquired config in ~/.oci/config and get the value of tenancy= for use with oci cli
```bash
cmiranda@tenancyName ~$ oci iam tenancy get --tenancy-id ocid1.tenancy.oc1..aaaaaa########################6h6lape
{
  "data": {
    "defined-tags": {
      "OracleInternalReserved": {
        "CostCenter": "XXXXXX",
        "OwnerEmail": "superadmin@company.com",
        "ServiceType": "IaaS",
        "UsageType": "field-sales"
      }
    },
    "description": "tenancyName",
    "freeform-tags": {},
    "home-region-key": "GRU",
    "id": "ocid1.tenancy.oc1..aaaaaa########################6h6lape",
    "name": "tenancyName",
    "upi-idcs-compatibility-layer-endpoint": null
  }
}
```

### Q: Why I got "No such file or directory" when use oci cli?

```bash
cmiranda@tenancyName ~$ oci iam tenancy get --tenancy-id oocid1.tenancy.oc1..aaaaaa########################6h6lape
Traceback (most recent call last):
  File "/opt/venv/bin/oci", line 8, in <module>
    sys.exit(cli())
             ^^^^^
*
*
*
  File "/opt/venv/lib/python3.12/site-packages/oci_cli/cli_root.py", line 581, in validate_label_private_key 
    with open(file_path, "r") as file:
         ^^^^^^^^^^^^^^^^^^^^
FileNotFoundError: [Errno 2] No such file or directory: '~/.oci/tenancyName.pem'

```
**A:** Inside docker container don't use key_file=~/.oci/yourKeyFile, use full path instead 

## Development

### Q: Can I install additional tools in the container?
**A:** Yes, but they won't persist after container restart. Add them to the appropriate Dockerfile for persistence.

### Q: How do I update Terraform/OCI CLI versions?
**A:** For the Oracle Linux image, update the version tags in the Dockerfile.oracle file:
```dockerfile
ARG OCI_CLI_VERSION=3.52
ARG TERRAFORM_VERSION=1.7.5
```

For the HashiCorp image, Terraform version is controlled by the base image tag. To update OCI CLI version:
```bash
docker compose build --build-arg OCI_CLI_VERSION=<new_version> --no-cache
```

## Troubleshooting

### Q: Container fails to start with permission errors
**A:** Check that your UID/GID match between host and container:
```bash
# [HOST] Check your UID/GID
id -u
id -g
```

### Q: Changes to my code aren't reflected in the container
**A:** Verify the correct volume mounting:
```bash
# [CONTAINER] List mounted volumes
mount | grep home
```

## Performance

### Q: Is there a performance impact using WSL?
**A:** Minimal impact for most operations. For better performance:
- Place project files in the Linux filesystem
- Avoid Windows-managed directories
- Use WSL2 instead of WSL1

### Q: Will the container consume too much memory?
**A:** The containers are designed to be lightweight. The Oracle Linux image may be slightly larger than the Alpine-based image. Monitor usage with:
```bash
# [HOST] Check container resources
docker stats container03
```

### Q: Is there a performance difference between the two base images?
**A:** The HashiCorp Alpine image is generally smaller and uses fewer resources, but the Oracle Linux image may have better compatibility with Oracle Cloud Infrastructure tools. For most development tasks, you won't notice significant performance differences.