#!/bin/bash

# Set variables
CHART_NAME="cast-hibernate-manager"
GITHUB_REPO="ronakforcast/castai_hibernation_manager"  # Replace with your actual GitHub repo
VERSION="0.1.0"

# Create directory structure for Helm chart
mkdir -p ${CHART_NAME}/{templates,charts,crds}

# Create Chart.yaml
cat > ${CHART_NAME}/Chart.yaml << EOF
apiVersion: v2
name: ${CHART_NAME}
description: A Helm chart for Cast.ai Hibernate Manager
version: ${VERSION}
appVersion: "1.0.0"
EOF

# Create values.yaml
cat > ${CHART_NAME}/values.yaml << EOF
replicaCount: 1

image:
  repository: castai/central_hibernate_manager
  tag: latest
  pullPolicy: IfNotPresent

apiKey:
  secretName: cast-api-key-secret
  secretKey: api-key

instanceType: t2.medium

schedules:
  - cluster_id: cluster1
    hibernate_cron: "0 22 * * *"
    resume_cron: "0 8 * * *"
  - cluster_id: cluster2
    hibernate_cron: "0 23 * * *"
    resume_cron: "0 9 * * *"
EOF

# Create templates for Kubernetes resources
# Secret Template
cat > ${CHART_NAME}/templates/secret.yaml << EOF
apiVersion: v1
kind: Secret
metadata:
  name: {{ .Values.apiKey.secretName }}
type: Opaque
data:
  {{ .Values.apiKey.secretKey }}: {{ .Values.apiKey.secretValue | b64enc }}
EOF

# ConfigMap Template
cat > ${CHART_NAME}/templates/configmap.yaml << EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: schedule-config
data:
  schedules.json: |
    {{ toJson .Values.schedules }}
EOF

# Deployment Template
cat > ${CHART_NAME}/templates/deployment.yaml << EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: cast-hibernate-manager
spec:
  replicas: {{ .Values.replicaCount }}
  selector:
    matchLabels:
      app: cast-hibernate-manager
  template:
    metadata:
      labels:
        app: cast-hibernate-manager
    spec:
      containers:
      - name: scheduler
        image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
        imagePullPolicy: {{ .Values.image.pullPolicy }}
        env:
        - name: INSTANCE_TYPE
          value: {{ .Values.instanceType }}
        envFrom:
        - secretRef:
            name: {{ .Values.apiKey.secretName }}
        volumeMounts:
        - name: config-volume
          mountPath: /etc/schedule
      volumes:
      - name: config-volume
        configMap:
          name: schedule-config
EOF

# Package the Helm chart
helm package ${CHART_NAME}

# Create or update Helm chart repository index
helm repo index . --url https://raw.githubusercontent.com/${GITHUB_REPO}/main/

# Optional: Remove temporary files
rm -f *.tgz

# Git commands to push to GitHub (uncomment and modify as needed)
# git init
# git add .
# git commit -m "Add Cast Hibernate Manager Helm Chart v${VERSION}"
# git branch -M main
# git remote add origin https://github.com/${GITHUB_REPO}.git
# git push -u origin main

echo "Helm chart for Cast Hibernate Manager has been created and prepared for deployment."