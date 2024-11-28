#!/bin/bash

# Variables
CHART_NAME="cast-hibernate-manager"
GITHUB_REPO="https://github.com/ronakforcast/castai_hibernation_manager.git"
GITHUB_PAGES_URL="https://ronakforcast.github.io/castai_hibernation_manager"
LOCAL_REPO_DIR="castai_hibernation_manager"
CHART_VERSION="1.0.0"

# Step 1: Package the Helm chart
helm package $CHART_NAME
if [ $? -ne 0 ]; then
  echo "Error: Failed to package the Helm chart."
  exit 1
fi

# # Step 2: Clone the GitHub repository
# if [ ! -d "$LOCAL_REPO_DIR" ]; then
#   git clone $GITHUB_REPO $LOCAL_REPO_DIR
# else
#   echo "Repository already cloned. Pulling latest changes..."
#   cd $LOCAL_REPO_DIR
#   git pull origin main
#   cd ..
# fi


# Step 3: Move packaged chart into the repository directory
# mv ${CHART_NAME}-${CHART_VERSION}.tgz $LOCAL_REPO_DIR/

# Step 4: Generate/Update index.yaml

helm repo index . --url $GITHUB_PAGES_URL
if [ $? -ne 0 ]; then
  echo "Error: Failed to generate the Helm repository index."
  exit 1
fi

# # Step 5: Commit and push changes
# git add .
# git commit -m "Add Helm chart $CHART_NAME version $CHART_VERSION"
# git push origin main
# if [ $? -ne 0 ]; then
#   echo "Error: Failed to push changes to GitHub."
#   exit 1
# fi

echo "Helm chart $CHART_NAME has been successfully published to GitHub Pages!"
echo
echo "================= Usage Instructions ================="
echo "1. Add your Helm repository:"
echo "   helm repo add castai-hibernate $GITHUB_PAGES_URL"
echo
echo "2. Update your Helm repositories:"
echo "   helm repo update"
echo
echo "3. Install the Helm chart:"
echo "   helm install my-release castai-hibernate/$CHART_NAME"
echo "======================================================"