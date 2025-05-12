#!/bin/bash
set -euo pipefail

for i in AWS AZURE GCP; do
  kubectl delete -f  "${GITHUB_RUN_ID}/${i}/cluster.yaml" --force &
done
