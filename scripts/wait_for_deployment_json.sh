#!/bin/bash
set -euo pipefail

TIMEOUT=$((10 * 60))
SECONDS=0

while (( SECONDS < TIMEOUT )); do
    echo "$TEST_MODE/$NAMESPACE"
    pods_json=$(KUBECONFIG="kcfg_$TEST_MODE" kubectl get pods -n "$NAMESPACE" -o json 2>/dev/null || true)

    if [[ -z "$pods_json" ]]; then
        echo "No pods found or error getting pods"
        sleep 3
        continue
    fi

    all_ready=true

    pod_count=$(jq '.items | length' <<< "$pods_json")
    if [[ "$pod_count" -eq 0 ]]; then
        echo "No pods found in the namespace yet"
        sleep 3
        continue
    fi

    echo "Checking $pod_count pods..."

    # Loop over each pod
    for row in $(jq -r '.items[] | @base64' <<< "$pods_json"); do
        _jq() {
            echo "${row}" | base64 --decode | jq -r "${1}"
        }

        name=$(_jq '.metadata.name')
        status=$(_jq '.status.phase')
        ready_containers=$(_jq '[.status.containerStatuses[] | select(.ready == true)] | length')
        total_containers=$(_jq '.status.containerStatuses | length')

        echo "- $name => Status: $status, Ready: $ready_containers/$total_containers"

        if [[ "$status" == "Running" || "$status" == "Completed" ]]; then
            if [[ "$ready_containers" -ne "$total_containers" ]]; then
                all_ready=false
            fi
        else
            all_ready=false
        fi
    done

    if $all_ready; then
        echo "✅ All pods are ready!"
        break
    else
        echo "⏳ Some pods are not ready yet..."
    fi

    sleep 3
done

if (( SECONDS >= TIMEOUT )); then
    echo "❌ Timeout reached: Some pods are still not ready"
    echo "🔍 Dumping pod statuses for debugging..."

    for row in $(jq -r '.items[] | @base64' <<< "$pods_json"); do
        _jq() {
            echo "${row}" | base64 --decode | jq -r "${1}"
        }

        pod_name=$(_jq '.metadata.name')
        pod_phase=$(_jq '.status.phase')

        echo "📦 Pod: $pod_name (Phase: $pod_phase)"

        container_count=$(_jq '.status.containerStatuses | length')
        for (( i=0; i<container_count; i++ )); do
            cname=$(_jq ".status.containerStatuses[$i].name")
            ready=$(_jq ".status.containerStatuses[$i].ready")
            state=$(_jq ".status.containerStatuses[$i].state | keys[0]")
            reason=$(_jq ".status.containerStatuses[$i].state.${state}.reason // \"-\"")
            message=$(_jq ".status.containerStatuses[$i].state.${state}.message // \"-\"")

            echo " └─ Container: $cname"
            echo "    • Ready: $ready"
            echo "    • State: $state"
            echo "    • Reason: $reason"
            echo "    • Message: $message"
        done

        echo ""
    done

    exit 1
fi
