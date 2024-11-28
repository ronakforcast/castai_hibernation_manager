#!/bin/bash

# Set chart name and create chart
CHART_NAME="cast-hibernate-manager"
helm create $CHART_NAME

# Clean up unnecessary files
rm -rf $CHART_NAME/templates/service.yaml $CHART_NAME/templates/ingress.yaml $CHART_NAME/templates/hpa.yaml $CHART_NAME/charts $CHART_NAME/tests

# Update Chart.yaml
cat <<EOF > $CHART_NAME/Chart.yaml
apiVersion: v2
name: $CHART_NAME
description: A Helm chart for managing hibernation schedules
version: 1.0.0
appVersion: "1.0"
EOF

# Create Secret template
cat <<EOF > $CHART_NAME/templates/secret.yaml
apiVersion: v1
kind: Secret
metadata:
  name: {{ .Values.secret.name }}
type: Opaque
data:
  api-key: {{ .Values.secret.apiKey | quote }}
EOF

# Create ConfigMap template
cat <<EOF > $CHART_NAME/templates/configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ .Values.configMap.name }}
data:
  schedules.json: |
    {{ .Values.configMap.schedules | toJson }}
EOF

# Create Deployment template
cat <<EOF > $CHART_NAME/templates/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ .Values.deployment.name }}
spec:
  replicas: {{ .Values.deployment.replicas }}
  selector:
    matchLabels:
      app: {{ .Values.deployment.labels.app }}
  template:
    metadata:
      labels:
        app: {{ .Values.deployment.labels.app }}
    spec:
      containers:
      - name: scheduler
        image: {{ .Values.deployment.image }}
        env:
        - name: INSTANCE_TYPE
          value: {{ .Values.deployment.instanceType | quote }}
        envFrom:
        - secretRef:
            name: {{ .Values.secret.name }}
        volumeMounts:
        - name: config-volume
          mountPath: /etc/schedule
      volumes:
      - name: config-volume
        configMap:
          name: {{ .Values.configMap.name }}
EOF

# Populate values.yaml with default values
cat <<EOF > $CHART_NAME/values.yaml
secret:
  name: cast-api-key-secret
  apiKey: "eW91cl9hcGlfa2V5"  # Base64 encoded API key

configMap:
  name: schedule-config
  schedules:
    - cluster_id: cluster1
      hibernate_cron: "0 22 * * *"
      resume_cron: "0 8 * * *"
    - cluster_id: cluster2
      hibernate_cron: "0 23 * * *"
      resume_cron: "0 9 * * *"

deployment:
  name: cast-hibernate-manager
  replicas: 1
  image: castai/central_hibernate_manager:latest
  instanceType: "t2.medium"
  labels:
    app: cast-hibernate-manager
EOF

echo "Helm chart $CHART_NAME has been set up successfully!"