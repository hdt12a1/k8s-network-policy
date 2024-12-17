#!/bin/bash

# Network Policy Debugging Script
# This script provides utilities for debugging Kubernetes Network Policies

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check prerequisites
check_prerequisites() {
    echo -e "${YELLOW}Checking prerequisites...${NC}"
    
    if ! command_exists kubectl; then
        echo -e "${RED}kubectl not found. Please install kubectl first.${NC}"
        exit 1
    fi
    
    # Check if connected to a cluster
    if ! kubectl cluster-info >/dev/null 2>&1; then
        echo -e "${RED}Not connected to a Kubernetes cluster.${NC}"
        exit 1
    }
    
    echo -e "${GREEN}Prerequisites check passed.${NC}"
}

# Function to check CNI status
check_cni_status() {
    local namespace=$1
    echo -e "${YELLOW}Checking CNI status...${NC}"
    
    # Check for common CNI plugins
    echo "Looking for CNI pods..."
    kubectl get pods -n $namespace | grep -i -E 'calico|weave|cilium|flannel'
    
    # Check CNI configuration
    echo -e "\nCNI Configuration:"
    kubectl get configmap -n $namespace | grep -i cni
}

# Function to verify network policies
verify_network_policies() {
    local namespace=$1
    echo -e "${YELLOW}Verifying Network Policies in namespace: $namespace${NC}"
    
    # List all network policies
    echo -e "\nNetwork Policies:"
    kubectl get networkpolicy -n $namespace
    
    # Show details of each policy
    for policy in $(kubectl get networkpolicy -n $namespace -o jsonpath='{.items[*].metadata.name}'); do
        echo -e "\nDetails for policy: $policy"
        kubectl describe networkpolicy $policy -n $namespace
    done
}

# Function to deploy a test pod
deploy_test_pod() {
    local namespace=$1
    local pod_name="network-policy-test-pod"
    
    echo -e "${YELLOW}Deploying test pod in namespace: $namespace${NC}"
    
    # Create test pod
    cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: $pod_name
  namespace: $namespace
  labels:
    app: network-policy-test
spec:
  containers:
  - name: netshoot
    image: nicolaka/netshoot
    command: ['sh', '-c', 'while true; do sleep 3600; done']
EOF
    
    # Wait for pod to be ready
    echo "Waiting for test pod to be ready..."
    kubectl wait --for=condition=ready pod/$pod_name -n $namespace --timeout=60s
    
    echo -e "${GREEN}Test pod deployed successfully.${NC}"
}

# Function to test connectivity
test_connectivity() {
    local namespace=$1
    local target=$2
    local port=${3:-80}
    
    echo -e "${YELLOW}Testing connectivity to $target:$port${NC}"
    
    kubectl exec -n $namespace network-policy-test-pod -- nc -zv $target $port
}

# Function to check pod labels
check_pod_labels() {
    local namespace=$1
    echo -e "${YELLOW}Checking pod labels in namespace: $namespace${NC}"
    
    kubectl get pods -n $namespace --show-labels
}

# Main menu
show_menu() {
    echo -e "${GREEN}Network Policy Debugging Menu${NC}"
    echo "1. Check CNI Status"
    echo "2. Verify Network Policies"
    echo "3. Deploy Test Pod"
    echo "4. Test Connectivity"
    echo "5. Check Pod Labels"
    echo "6. Exit"
}

# Main script
main() {
    check_prerequisites
    
    while true; do
        show_menu
        read -p "Enter your choice (1-6): " choice
        
        case $choice in
            1)
                read -p "Enter namespace (default: kube-system): " namespace
                namespace=${namespace:-kube-system}
                check_cni_status "$namespace"
                ;;
            2)
                read -p "Enter namespace: " namespace
                verify_network_policies "$namespace"
                ;;
            3)
                read -p "Enter namespace: " namespace
                deploy_test_pod "$namespace"
                ;;
            4)
                read -p "Enter namespace: " namespace
                read -p "Enter target service/pod: " target
                read -p "Enter port (default: 80): " port
                port=${port:-80}
                test_connectivity "$namespace" "$target" "$port"
                ;;
            5)
                read -p "Enter namespace: " namespace
                check_pod_labels "$namespace"
                ;;
            6)
                echo -e "${GREEN}Exiting...${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}Invalid choice${NC}"
                ;;
        esac
        
        echo
        read -p "Press enter to continue..."
    done
}

# Run main function
main
