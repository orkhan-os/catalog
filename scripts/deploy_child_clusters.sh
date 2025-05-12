#!/bin/bash
set -euo pipefail

AWS_MASTER_NUMBER=$(echo "$AWS_SETTINGS" | jq -r '.master_number')
AWS_MASTER_INSTANCE_TYPE=$(echo "$AWS_SETTINGS" | jq -r '.master_type')
AWS_WORKER_NUMBER=$(echo "$AWS_SETTINGS" | jq -r '.worker_number')
AWS_WORKER_INSTANCE_TYPE=$(echo "$AWS_SETTINGS" | jq -r '.worker_type')

AZURE_MASTER_NUMBER=$(echo "$AZURE_SETTINGS" | jq -r '.master_number')
AZURE_MASTER_INSTANCE_TYPE=$(echo "$AZURE_SETTINGS" | jq -r '.master_type')
AZURE_WORKER_NUMBER=$(echo "$AZURE_SETTINGS" | jq -r '.worker_number')
AZURE_WORKER_INSTANCE_TYPE=$(echo "$AZURE_SETTINGS" | jq -r '.worker_type')

GCP_MASTER_NUMBER=$(echo "$GCP_SETTINGS" | jq -r '.master_number')
GCP_MASTER_INSTANCE_TYPE=$(echo "$GCP_SETTINGS" | jq -r '.master_type')
GCP_WORKER_NUMBER=$(echo "$GCP_SETTINGS" | jq -r '.worker_number')
GCP_WORKER_INSTANCE_TYPE=$(echo "$GCP_SETTINGS" | jq -r '.worker_type')

for i in AWS AZURE GCP; do
  mkdir -p "${GITHUB_RUN_ID}/${i}"
  cp "/home/runner/${i}/cluster.yaml" "${GITHUB_RUN_ID}/${i}/cluster.yaml"

  master_number_var="${i}_MASTER_NUMBER"
  master_instance_var="${i}_MASTER_INSTANCE_TYPE"
  worker_number_var="${i}_WORKER_NUMBER"
  worker_instance_var="${i}_WORKER_INSTANCE_TYPE"
  cluster_name="$(echo "${i,,}")-cluster-${GITHUB_RUN_ID}"

  sed -i "s/MASTER_NUMBER/${!master_number_var}/g" "${GITHUB_RUN_ID}/${i}/cluster.yaml"
  sed -i "s/WORKER_NUMBER/${!worker_number_var}/g" "${GITHUB_RUN_ID}/${i}/cluster.yaml"
  sed -i "s/MASTER_INSTANCE/${!master_instance_var}/g" "${GITHUB_RUN_ID}/${i}/cluster.yaml"
  sed -i "s/WORKER_INSTANCE/${!worker_instance_var}/g" "${GITHUB_RUN_ID}/${i}/cluster.yaml"
  sed -i "s/CLUSTER_LABEL/${GITHUB_RUN_ID}/g" "${GITHUB_RUN_ID}/${i}/cluster.yaml"
  sed -i "s/CLUSTER_NAME/${cluster_name}/g" "${GITHUB_RUN_ID}/${i}/cluster.yaml"

  kubectl create -f  "${GITHUB_RUN_ID}/${i}/cluster.yaml"
done










