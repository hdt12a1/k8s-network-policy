#!/bin/bash

# Script to find AWS S3 CIDR ranges for network policies

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to check dependencies
check_dependencies() {
    local missing_deps=0
    
    if ! command -v jq &> /dev/null; then
        echo -e "${RED}Error: jq is required but not installed.${NC}"
        echo "Install with: brew install jq"
        missing_deps=1
    fi
    
    if ! command -v curl &> /dev/null; then
        echo -e "${RED}Error: curl is required but not installed.${NC}"
        missing_deps=1
    fi
    
    if [ $missing_deps -eq 1 ]; then
        exit 1
    fi
}

# Function to get IP ranges for a specific region
get_region_cidrs() {
    local region=$1
    local temp_file="ip-ranges.json"
    
    echo -e "${GREEN}Fetching S3 CIDR ranges for region: ${region}${NC}"
    
    # Download IP ranges if not already downloaded
    if [ ! -f "$temp_file" ]; then
        echo "Downloading AWS IP ranges..."
        curl -s -o "$temp_file" https://ip-ranges.amazonaws.com/ip-ranges.json
    fi
    
    echo -e "\n${YELLOW}IPv4 Ranges:${NC}"
    jq -r --arg region "$region" '.prefixes[] | select(.service=="S3" and .region==$region) | .ip_prefix' "$temp_file"
    
    echo -e "\n${YELLOW}IPv6 Ranges:${NC}"
    jq -r --arg region "$region" '.ipv6_prefixes[] | select(.service=="S3" and .region==$region) | .ipv6_prefix' "$temp_file"
}

# Function to generate network policy YAML
generate_policy() {
    local region=$1
    local temp_file="ip-ranges.json"
    local policy_file="s3-network-policy-${region}.yaml"
    
    echo -e "${GREEN}Generating network policy for region: ${region}${NC}"
    
    # Create policy header
    cat > "$policy_file" << EOF
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-s3-access-${region}
  namespace: your-namespace
spec:
  podSelector:
    matchLabels:
      app: your-app
  policyTypes:
    - Egress
  egress:
    - to:
EOF
    
    # Add IPv4 CIDRs
    jq -r --arg region "$region" '.prefixes[] | select(.service=="S3" and .region==$region) | "        - ipBlock:\n            cidr: " + .ip_prefix' "$temp_file" >> "$policy_file"
    
    # Add ports
    cat >> "$policy_file" << EOF
      ports:
        - protocol: TCP
          port: 443
    # Allow DNS resolution
    - to:
        - namespaceSelector:
            matchLabels:
              kubernetes.io/metadata.name: kube-system
        - podSelector:
            matchLabels:
              k8s-app: kube-dns
      ports:
        - protocol: UDP
          port: 53
        - protocol: TCP
          port: 53
EOF
    
    echo -e "${GREEN}Network policy generated: ${policy_file}${NC}"
}

# Main script
main() {
    check_dependencies
    
    local region=${1:-"ap-southeast-1"}  # Default to ap-southeast-1 if no region specified
    
    echo -e "${GREEN}AWS S3 CIDR Range Finder${NC}"
    echo "================================"
    
    get_region_cidrs "$region"
    generate_policy "$region"
    
    # Cleanup
    rm -f ip-ranges.json
}

# Show usage if --help or -h is passed
if [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
    echo "Usage: $0 [region]"
    echo "Example: $0 ap-southeast-1"
    exit 0
fi

main "$@"
