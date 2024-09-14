# Ghimele's Homelab Configuration Repository

Welcome to the Homelab Configuration repository! This repository contains the configuration and automation scripts used to manage and deploy resources in the homelab environment. It includes Ansible playbooks, Kubernetes manifests, Helm charts, and CI/CD workflows.

## Repository Structure

Here's an overview of the repository structure:
```
homelab/
├── .github/              # GitHub Actions workflows and configurations
│   └── workflows/        # GitHub Actions workflows
│       ├── ci.yml        # Example workflow for continuous integration
│       └── deploy.yml    # Example workflow for deployment
├── ansible/              # Ansible configuration
│   └── playbooks/        # Ansible playbooks for various tasks
│   └── tasks/            # Ansible tasks
│   └── inventory/        # Ansible inventory files
├── docs/
│   └── adr/              # Architecture Decision Records (ADRs)
├── kubernetes/
│   ├── manifests/        # Base Kubernetes manifests and Kustomize overlays
│   │   ├── base/         # Base Kubernetes manifests (common to all environments)
│   │   ├── overlays/
│   │   │   ├── dev/      # Dev-specific Kubernetes configurations using Kustomize
│   │   │   ├── test/     # Test-specific Kubernetes configurations using Kustomize
│   │   │   ├── prod/     # Production-specific Kubernetes configurations using Kustomize
│   └── helm/             # Helm charts and values files
│       ├── charts/       # Helm charts (reusable across environments)
│       │   └── my-app/   # Example Helm chart for 'my-app'
│       └── values/       # Environment-specific Helm values files
│           ├── dev/      # Values for the Dev environment
│           ├── test/     # Values for the Test environment
│           └── prod/     # Values for the Production environment
└── scripts/              # Any additional automation or management scripts
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

  Use kustomize to build and apply Kubernetes manifests from the kubernetes/manifests/ directory.
  Use Helm to manage Helm charts and values from the kubernetes/helm/ directory.

### 4. CI/CD with GitHub Actions

  Configure GitHub Actions workflows in the .github/workflows/ directory for automated testing and deployment.
