#!/usr/bin/env bash

# Script to debug environment variables by creating a temporary pod
# with the exact same env configuration and printing the actual merged result

# Ensure we're running with bash
if [ -z "$BASH_VERSION" ]; then
    echo "Error: This script requires bash. Please run with: bash $0 $@"
    exit 1
fi

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

usage() {
    echo "Usage: $0 -n <namespace> -p <pod-name> [-c <container-name>] [-k]"
    echo "  -n: Namespace"
    echo "  -p: Pod name"
    echo "  -c: Container name (optional, uses first container if not specified)"
    echo "  -k: Keep the debug pod after execution (default: delete)"
    echo ""
    echo "Examples:"
    echo "  $0 -n default -p my-pod"
    echo "  $0 -n kube-system -p coredns-123456 -c coredns"
    echo "  $0 -n default -p my-pod -k  # Keep debug pod"
    exit 1
}

# Parse arguments
KEEP_POD=false
while getopts "n:p:c:kh" opt; do
    case $opt in
        n) NAMESPACE="$OPTARG" ;;
        p) POD_NAME="$OPTARG" ;;
        c) CONTAINER_NAME="$OPTARG" ;;
        k) KEEP_POD=true ;;
        h) usage ;;
        *) usage ;;
    esac
done

if [ -z "$NAMESPACE" ] || [ -z "$POD_NAME" ]; then
    echo -e "${RED}Error: Namespace and pod name are required${NC}"
    usage
fi

echo -e "${BLUE}==================================================================${NC}"
echo -e "${BLUE}Environment Variable Debug (Live Pod Method)${NC}"
echo -e "${BLUE}Source Pod: ${GREEN}$POD_NAME${BLUE} in namespace: ${GREEN}$NAMESPACE${NC}"
echo -e "${BLUE}==================================================================${NC}"
echo ""

# Check if pod exists
if ! kubectl get pod "$POD_NAME" -n "$NAMESPACE" &>/dev/null; then
    echo -e "${RED}Error: Pod '$POD_NAME' not found in namespace '$NAMESPACE'${NC}"
    exit 1
fi

# Get pod YAML
POD_YAML=$(kubectl get pod "$POD_NAME" -n "$NAMESPACE" -o json)

# If container name not specified, get the first container
if [ -z "$CONTAINER_NAME" ]; then
    CONTAINER_NAME=$(echo "$POD_YAML" | jq -r '.spec.containers[0].name')
    echo -e "${YELLOW}No container specified, using: ${CONTAINER_NAME}${NC}"
    echo ""
fi

# Verify container exists
CONTAINER_EXISTS=$(echo "$POD_YAML" | jq -r ".spec.containers[] | select(.name==\"$CONTAINER_NAME\") | .name")
if [ -z "$CONTAINER_EXISTS" ]; then
    echo -e "${RED}Error: Container '$CONTAINER_NAME' not found in pod${NC}"
    echo -e "${YELLOW}Available containers:${NC}"
    echo "$POD_YAML" | jq -r '.spec.containers[].name'
    exit 1
fi

# Get container spec
CONTAINER_SPEC=$(echo "$POD_YAML" | jq ".spec.containers[] | select(.name==\"$CONTAINER_NAME\")")

# Extract env and envFrom
ENV_SPEC=$(echo "$CONTAINER_SPEC" | jq '.env // []')
ENV_FROM_SPEC=$(echo "$CONTAINER_SPEC" | jq '.envFrom // []')

# Generate a unique name for the debug pod
DEBUG_POD_NAME="debug-env-$(date +%s)-$((RANDOM % 9000 + 1000))"

echo -e "${CYAN}Creating temporary debug pod: ${GREEN}${DEBUG_POD_NAME}${NC}"
echo -e "${YELLOW}This pod will have the exact same environment configuration...${NC}"
echo ""

# Create the debug pod manifest
DEBUG_POD_MANIFEST=$(cat <<EOF
{
  "apiVersion": "v1",
  "kind": "Pod",
  "metadata": {
    "name": "${DEBUG_POD_NAME}",
    "namespace": "${NAMESPACE}",
    "labels": {
      "debug": "env-debug",
      "source-pod": "${POD_NAME}"
    }
  },
  "spec": {
    "restartPolicy": "Never",
    "containers": [
      {
        "name": "debug",
        "image": "busybox:latest",
        "command": ["/bin/sh", "-c"],
        "args": ["env | sort && echo '---END-OF-ENV---' && sleep 5"],
        "env": ${ENV_SPEC},
        "envFrom": ${ENV_FROM_SPEC}
      }
    ]
  }
}
EOF
)

# Create the debug pod
echo "$DEBUG_POD_MANIFEST" | kubectl apply -f - >/dev/null

# Function to cleanup
cleanup() {
    if [ "$KEEP_POD" = false ]; then
        echo ""
        echo -e "${YELLOW}Cleaning up debug pod...${NC}"
        kubectl delete pod "$DEBUG_POD_NAME" -n "$NAMESPACE" --wait=false >/dev/null 2>&1 || true
        echo -e "${GREEN}Debug pod deleted${NC}"
    else
        echo ""
        echo -e "${YELLOW}Debug pod kept: ${GREEN}${DEBUG_POD_NAME}${NC}"
        echo -e "${YELLOW}To view logs again: ${BLUE}kubectl logs -n ${NAMESPACE} ${DEBUG_POD_NAME}${NC}"
        echo -e "${YELLOW}To delete later: ${BLUE}kubectl delete pod -n ${NAMESPACE} ${DEBUG_POD_NAME}${NC}"
    fi
}

trap cleanup EXIT

# Wait for pod to start
echo -e "${YELLOW}Waiting for debug pod to start...${NC}"
TIMEOUT=60
ELAPSED=0
while [ $ELAPSED -lt $TIMEOUT ]; do
    POD_STATUS=$(kubectl get pod "$DEBUG_POD_NAME" -n "$NAMESPACE" -o jsonpath='{.status.phase}' 2>/dev/null || echo "")

    if [ "$POD_STATUS" = "Running" ] || [ "$POD_STATUS" = "Succeeded" ]; then
        break
    fi

    if [ "$POD_STATUS" = "Failed" ] || [ "$POD_STATUS" = "Error" ]; then
        echo -e "${RED}Debug pod failed to start${NC}"
        kubectl get pod "$DEBUG_POD_NAME" -n "$NAMESPACE"
        kubectl describe pod "$DEBUG_POD_NAME" -n "$NAMESPACE"
        exit 1
    fi

    sleep 1
    ELAPSED=$((ELAPSED + 1))
done

if [ $ELAPSED -ge $TIMEOUT ]; then
    echo -e "${RED}Timeout waiting for debug pod to start${NC}"
    kubectl describe pod "$DEBUG_POD_NAME" -n "$NAMESPACE"
    exit 1
fi

# Wait a bit more for the container to execute
sleep 2

echo -e "${GREEN}Debug pod started successfully!${NC}"
echo ""

echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}ACTUAL MERGED ENVIRONMENT VARIABLES${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Get the logs and parse the environment
ENV_OUTPUT=$(kubectl logs "$DEBUG_POD_NAME" -n "$NAMESPACE" 2>/dev/null || echo "")

if [ -z "$ENV_OUTPUT" ]; then
    echo -e "${RED}Failed to get logs from debug pod${NC}"
    kubectl describe pod "$DEBUG_POD_NAME" -n "$NAMESPACE"
    exit 1
fi

# Extract only the env output (before the marker)
ACTUAL_ENV=$(echo "$ENV_OUTPUT" | grep -B 10000 -- '---END-OF-ENV---' | grep -v -- '---END-OF-ENV---')

if [ -z "$ACTUAL_ENV" ]; then
    echo -e "${RED}No environment variables captured${NC}"
    exit 1
fi

# Display the environment variables
echo "$ACTUAL_ENV" | while IFS='=' read -r key value; do
    if [ -n "$key" ]; then
        echo -e "  ${GREEN}${key}${NC}=${YELLOW}${value}${NC}"
    fi
done

echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}SUMMARY${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

TOTAL_VARS=$(echo "$ACTUAL_ENV" | wc -l | tr -d ' ')
echo -e "  Total environment variables: ${GREEN}${TOTAL_VARS}${NC}"
echo ""

# Show what configuration was used
HAS_ENV=$(echo "$ENV_SPEC" | jq 'length')
HAS_ENV_FROM=$(echo "$ENV_FROM_SPEC" | jq 'length')

echo -e "  Configuration used:"
if [ "$HAS_ENV" -gt 0 ]; then
    echo -e "    - ${GREEN}${HAS_ENV}${NC} entries in 'env' array"
fi
if [ "$HAS_ENV_FROM" -gt 0 ]; then
    echo -e "    - ${GREEN}${HAS_ENV_FROM}${NC} entries in 'envFrom' array"
fi

echo ""
echo -e "${BLUE}==================================================================${NC}"
echo -e "${BLUE}This is the ACTUAL environment that Kubernetes creates${NC}"
echo -e "${BLUE}==================================================================${NC}"
