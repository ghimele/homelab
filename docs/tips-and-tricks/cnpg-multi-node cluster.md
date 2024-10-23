# How to configure a CNPG multi node cluster

Apply the labels using selectors with kubectl label node

```bash
kubectl label node cnpg-worker5 node-role.kubernetes.io/postgres=
```

Below is a sample configuration to ensure that a PostgreSQL Cluster is deployed on postgres nodes, with its instances distributed across different nodes:

```yaml
  affinity:
    enablePodAntiAffinity: true
    topologyKey: kubernetes.io/hostname
    podAntiAffinityType: required
    nodeSelector:
      node-role.kubernetes.io/postgres: ""
    tolerations:
    - key: node-role.kubernetes.io/postgres
      operator: Exists
      effect: NoSchedule
```

## References

[CloudNativePG Recipe 10 - Simulating Production PostgreSQL on Kubernetes with Kind](https://www.gabrielebartolini.it/articles/2024/08/cloudnativepg-recipe-10-simulating-production-postgresql-on-kubernetes-with-kind/)

[CNPG Scheduling](https://cloudnative-pg.io/documentation/current/scheduling/#node-selection-through-nodeselector)
