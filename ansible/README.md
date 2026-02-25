# Ansible Automation for Homelab

This `ansible` folder contains the automation code for configuring and managing your homelab systems using [Ansible](https://www.ansible.com/).
It includes playbooks, roles, tasks, and inventory files to automate the setup of desktops, servers, and other infrastructure components.

## Structure

- **ansible.cfg**: Ansible configuration file.
- **inventory/**: Host and group inventory files for different environments (e.g., linux_desktop, linux_server, windows).
- **playbooks/**: Individual playbooks for specific tasks or roles.
- **roles/**: Reusable role definitions for configuring different types of machines.
- **tasks/**: Standalone task files for modular automation.
- **site.yaml**: The main playbook that orchestrates the overall configuration.

## Usage

### 1. Requirements

- Ansible must be installed on the target machine. You can install it with:

  ```bash
  sudo apt update && sudo apt install ansible -y
  ```

### 2. Running with `ansible-pull`

This repository is designed to be used with `ansible-pull`, which allows each machine to pull its configuration from the Git repository and apply it locally. This is ideal for self-updating, GitOps-style automation.

#### Example Command

```bash
sudo ansible-pull -U https://github.com/ghimele/homelab.git ./ansible/site.yaml -i ./ansible/inventory/linux_desktop.yaml --extra-vars "machine_type=linux_desktop"
```

- `-U <repo-url>`: The Git repository to pull from.
- `<playbook>`: The main playbook to run (e.g., `./ansible/site.yaml`).
- `-i <inventory>`: The inventory file specifying the target hosts/groups.
- `--extra-vars`: Additional variables, such as `machine_type`, to customize the run.

#### Customizing

- Use the appropriate inventory file for your machine type (e.g., `linux_desktop.yaml`, `linux_server.yaml`).
- Adjust `machine_type` and other variables as needed for your environment.

## Notes

- All changes should be made via pull requests to ensure consistency and traceability.
- Review the playbooks and roles before running to understand what will be configured on your systems.

---
For more details, see the main project `README.md` or the documentation in the `docs/` folder.
