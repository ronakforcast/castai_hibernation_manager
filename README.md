# castai_hibernation_manager
# Helm Chart Installation Guide for Cast Hibernate Manager

## Prerequisites
- Kubernetes cluster
- Helm 3.x installed
- `kubectl` configured to connect to your cluster

## Installation Methods

### 1. Add Helm Repository
```bash
# Add the Helm repository
helm repo add castai-hibernation-manager https://raw.githubusercontent.com/ronakforcast/castai_hibernation_manager/main/

# Update repositories
helm repo update
```

### 2. Install from Repository
```bash
helm install cast-hibernate-manager castai-hibernation-manager/cast-hibernate-manager \
  --set apiKey.secretValue=YOUR_CAST_AI_API_KEY \
  --namespace cast-automation \
  --create-namespace
```

## Configuration Options

### Custom Configuration File
Create a `custom-values.yaml` with your specific configurations:

```yaml
replicaCount: 1
instanceType: t3.medium

apiKey:
  secretValue: "your_base64_encoded_cast_ai_api_key"

schedules:
  - cluster_id: "production-cluster"
    hibernate_cron: "0 22 * * *"
    resume_cron: "0 8 * * *"
  - cluster_id: "staging-cluster"
    hibernate_cron: "0 23 * * *"
    resume_cron: "0 9 * * *"
```

### Install Using Custom Values
```bash
helm install cast-hibernate-manager castai-hibernation-manager/cast-hibernate-manager \
  -f custom-values.yaml \
  --namespace cast-automation
```

## Useful Helm Commands

### Verify Installation
```bash
# List installed releases
helm list -n cast-automation

# Check release status
helm status cast-hibernate-manager -n cast-automation
```

### Upgrade Deployment
```bash
helm upgrade cast-hibernate-manager castai-hibernation-manager/cast-hibernate-manager \
  --set apiKey.secretValue=NEW_API_KEY \
  -n cast-automation
```

### Uninstall
```bash
helm uninstall cast-hibernate-manager -n cast-automation
```

## API Key Preparation

### Preparing the API Key
1. Get your Cast.ai API Key from the Cast.ai platform
2. Base64 encode the API key:
   ```bash
   echo -n "your_actual_cast_ai_api_key" | base64
   ```
3. Use the base64 encoded value when installing the chart

## Troubleshooting
1. Ensure API key is correctly base64 encoded
2. Check pod logs: 
   ```bash
   kubectl logs -l app=cast-hibernate-manager -n cast-automation
   ```
3. Verify secret and configmap creation:
   ```bash
   kubectl get secrets,configmaps -n cast-automation
   ```


