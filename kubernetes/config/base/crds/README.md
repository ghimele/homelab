# CRDs

Some services need [`CustomResourceDefinition`s](https://kubernetes.io/docs/tasks/extend-kubernetes/custom-resources/custom-resource-definitions/) to provide their functionalities. To prevent race conditions with the actual usage of those definitions, The installation of CRDs is performed under the config section which will be deployed **before** the [infrastructure](/kubernetes/infrastructure/) and [apps](/kubernetes/apps/) sections. Inside the corresponding `HelmRelease`s the deployment of CRDs is skipped.

The following services require CRDs which are deployed by this section:

- [`cert-manager`](/kubernetes/infrastructure/cert-manager/)
- [`kube-prometheus-stack`](/kubernetes/infrastructure/kube-prometheus-stack/)