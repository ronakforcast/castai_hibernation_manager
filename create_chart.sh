#!/bin/bash

# Exit immediately if any command fails
set -e

# Define variables
CHART_NAME="cluster-hibernate-manager-chart"
CHART_VERSION="0.1.0"
IMAGE_REPO="castai/central_hibernate_manager"
IMAGE_TAG="latest"
INSTANCE_TYPE="t3.large"
GITHUB_USER="ronakforcast"  # Replace with your GitHub username
GITHUB_REPO="castai_hibernation_manager"        # Replace with your GitHub repository name

# Create a new Helm chart
echo "Creating Helm chart: $CHART_NAME"
helm create $CHART_NAME

# Navigate into the chart directory
cd $CHART_NAME

# Update Chart.yaml
cat <<EOF > Chart.yaml
apiVersion: v2
name: $CHART_NAME
description: A Helm chart for deploying a cluster scheduler
type: application
version: $CHART_VERSION
appVersion: "1.0"
EOF

# Update values.yaml
cat <<EOF > values.yaml
replicaCount: 1
image:
  repository: $IMAGE_REPO
  tag: $IMAGE_TAG
  pullPolicy: IfNotPresent

secret:
  apiKey: "eW91cl9hcGlfa2V5"  # Base64 encoded

config:
  instanceType: "$INSTANCE_TYPE"
  schedules:
    - cluster_id: cluster1
      hibernate_cron: "0 22 * * *"
      resume_cron: "0 8 * * *"
    - cluster_id: cluster2
      hibernate_cron: "0 23 * * *"
      resume_cron: "0 9 * * *"
EOF

# Create secret template
cat <<EOF > templates/secret.yaml
apiVersion: v1
kind: Secret
metadata:
  name: {{ .Release.Name }}-api-key-secret
type: Opaque
data:
  api-key: {{ .Values.secret.apiKey | quote }}
EOF

# Create configmap template
cat <<EOF > templates/configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ .Release.Name }}-schedule-config
data:
  schedules.json: |
    {{ toJson .Values.config.schedules | nindent 4 }}
EOF

# Create deployment template
cat <<EOF > templates/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ .Release.Name }}-cluster-scheduler
spec:
  replicas: {{ .Values.replicaCount }}
  selector:
    matchLabels:
      app: {{ .Release.Name }}-scheduler
  template:
    metadata:
      labels:
        app: {{ .Release.Name }}-scheduler
    spec:
      containers:
        - name: scheduler
          image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
          imagePullPolicy: {{ .Values.image.pullPolicy }}
          env:
            - name: INSTANCE_TYPE
              value: {{ .Values.config.instanceType }}
          envFrom:
            - secretRef:
                name: {{ .Release.Name }}-api-key-secret
          volumeMounts:
            - name: config-volume
              mountPath: /etc/schedule
      volumes:
        - name: config-volume
          configMap:
            name: {{ .Release.Name }}-schedule-config
EOF

# Package the Helm chart
echo "Packaging Helm chart..."
helm package .

# Move back to the parent directory
cd ..

# Generate index.yaml for the Helm repo
echo "Creating Helm repo index..."
helm repo index . --url https://$GITHUB_USER.github.io/$GITHUB_REPO

# Initialize a Git repository
# echo "Initializing Git repository..."
# git init
# git add .
# git commit -m "Initial commit of Helm chart"

# Add remote repository and push to GitHub
# echo "Adding remote GitHub repository..."
# git remote add origin https://github.com/$GITHUB_USER/$GITHUB_REPO.git
# git branch -M main
# git push -u origin main

# Print completion message
echo "Helm chart created, packaged, and pushed to GitHub repository."
echo "Ensure GitHub Pages is enabled under Settings > Pages in your repository."