# Ghimele's Homelab Configuration Repository
![GitHub tag status](https://img.shields.io/github/checks-status/ghimele/homelab/main?style=for-the-badge)
![GitHub Actions Workflow Status](https://img.shields.io/github/actions/workflow/status/ghimele/homelab/ci.yaml?style=for-the-badge)
 [![Pipeline (docs)](https://img.shields.io/github/actions/workflow/status/ghimele/homelab/docs.yml?branch=main&label=docs&style=for-the-badge)](https://github.com/ghimele/homelab/actions/workflows/docs.yml) ![GitHub commit activity](https://img.shields.io/github/commit-activity/m/ghimele/homelab?style=for-the-badge) [![GitHub Last Commit](https://img.shields.io/github/last-commit/ghimele/homelab?style=for-the-badge)](https://github.com/ghimele/homelab/commits/main) ![GitHub top language](https://img.shields.io/github/languages/top/ghimele/homelab?style=for-the-badge) ![GitHub repo size](https://img.shields.io/github/repo-size/ghimele/homelab?style=for-the-badge) [![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg?style=for-the-badge)](https://opensource.org/licenses/MIT)

![Kubernetes](https://img.shields.io/badge/kubernetes-%23326ce5.svg?style=for-the-badge&logo=kubernetes&logoColor=white) ![Ansible](https://img.shields.io/badge/ansible-%231A1918.svg?style=for-the-badge&logo=ansible&logoColor=white) ![Flux](https://img.shields.io/badge/flux-5468ff?style=for-the-badge&logo=flux&logoColor=white)


Welcome to the Homelab Configuration repository! This repository contains the configuration and automation scripts used to manage and deploy resources in the homelab environment. It includes Ansible playbooks, Kubernetes manifests, Helm charts, and CI/CD workflows.

## Repository Structure

Here's an overview of the repository structure:
```bash
├── .github/                # GitHub Actions workflows
├── ansible/                # Ansible playbooks and tasks for system automation
│   ├── inventory/          # Ansible inventory files
│   ├── playbooks/          # Ansible playbooks for various tasks
│   └── tasks/              # Individual tasks
├── docs/                   # Documentation and ADRs (Architecture Decision Records)
│   └── adr/
├── kubernetes/             # Kubernetes clusters config folder.
│   ├── apps/               # Application-specific configurations (base, dev, prod, test).
│   ├── clusters/           # Cluster-specific configurations (dev, prod, test).
│   ├── config/             # Base and environment-specific configurations for Kubernetes custom resources such as cert issuers and networks policies
│   └── infrastructure/     # Infr-specific configurations (base, dev, prod, test). Contains common infra tools for Kubernetes controllers such as traefik and cert-manager
├── management/             # Management services (e.g., backrest, portainer, xen-orchestra). The services are installed in a deidated VM using docker compose.
└── scripts/                # Automation and management scripts
```

## Getting Started

To get started with the homelab configuration, follow these steps:

### 1. Clone the Repository
  ```bash
  git clone https://github.com/ghimele/homelab.git
  cd homelab
  ```
### 2. Setup Ansible

  Install Ansible on your local machine.
  Configure your inventory files in ansible/inventories/ as needed.
  Run playbooks from ansible/playbooks/ to configure your systems.
### 3. Kubernetes Configuration
  The Kubernetes Configuration is managed by Fluxcd, see the CD section.

### 4. Continuos Integration with GitHub Actions
  Configure GitHub Actions workflows in the .github/workflows/ directory for automated testing and deployment.

### 5. Continuous Deployment with FluxCD
  FluxCD manages the continuous deployment of the Kubernetes resources. The Flux configuration is located under kubernetes/clusters/<environment>. Ensure that your FluxCD setup is properly synced with this repository to automate deployments.