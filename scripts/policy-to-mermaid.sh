#!/bin/bash

# Convert Kubernetes Network Policies to Mermaid diagrams
# This script takes a network policy YAML and converts it to a Mermaid diagram

# Color definitions
ALLOW_COLOR="#90EE90"
DENY_COLOR="#FFB6C1"
DEFAULT_COLOR="#ADD8E6"

generate_mermaid() {
    local policy_file=$1
    
    echo "```mermaid"
    echo "graph LR"
    
    # Extract policy name and namespace
    local policy_name=$(yq e '.metadata.name' "$policy_file")
    local namespace=$(yq e '.metadata.namespace' "$policy_file")
    
    echo "    %% Network Policy: $policy_name in namespace: $namespace"
    
    # Process pod selector
    local pod_selector=$(yq e '.spec.podSelector' "$policy_file")
    echo "    subgraph $namespace"
    
    # Process ingress rules
    if yq e '.spec.policyTypes[] | select(. == "Ingress")' "$policy_file" > /dev/null; then
        process_ingress_rules "$policy_file"
    fi
    
    # Process egress rules
    if yq e '.spec.policyTypes[] | select(. == "Egress")' "$policy_file" > /dev/null; then
        process_egress_rules "$policy_file"
    fi
    
    echo "    end"
    echo "```"
}

process_ingress_rules() {
    local policy_file=$1
    
    # Extract ingress rules
    yq e '.spec.ingress[]' "$policy_file" | while read -r rule; do
        local from=$(echo "$rule" | yq e '.from[]')
        local ports=$(echo "$rule" | yq e '.ports[]')
        
        # Process each source
        echo "$from" | while read -r source; do
            if [[ $(echo "$source" | yq e 'has("podSelector")') == "true" ]]; then
                local labels=$(echo "$source" | yq e '.podSelector.matchLabels')
                echo "    Source[\"Pod: $labels\"] -->|Allow| Target"
            fi
            
            if [[ $(echo "$source" | yq e 'has("namespaceSelector")') == "true" ]]; then
                local ns_labels=$(echo "$source" | yq e '.namespaceSelector.matchLabels')
                echo "    NamespaceSource[\"NS: $ns_labels\"] -->|Allow| Target"
            fi
            
            if [[ $(echo "$source" | yq e 'has("ipBlock")') == "true" ]]; then
                local cidr=$(echo "$source" | yq e '.ipBlock.cidr')
                echo "    External[\"IP: $cidr\"] -->|Allow| Target"
            fi
        done
    done
}

process_egress_rules() {
    local policy_file=$1
    
    # Extract egress rules
    yq e '.spec.egress[]' "$policy_file" | while read -r rule; do
        local to=$(echo "$rule" | yq e '.to[]')
        local ports=$(echo "$rule" | yq e '.ports[]')
        
        # Process each destination
        echo "$to" | while read -r dest; do
            if [[ $(echo "$dest" | yq e 'has("podSelector")') == "true" ]]; then
                local labels=$(echo "$dest" | yq e '.podSelector.matchLabels')
                echo "    Target -->|Allow| Dest[\"Pod: $labels\"]"
            fi
            
            if [[ $(echo "$dest" | yq e 'has("namespaceSelector")') == "true" ]]; then
                local ns_labels=$(echo "$dest" | yq e '.namespaceSelector.matchLabels')
                echo "    Target -->|Allow| NSDest[\"NS: $ns_labels\"]"
            fi
            
            if [[ $(echo "$dest" | yq e 'has("ipBlock")') == "true" ]]; then
                local cidr=$(echo "$dest" | yq e '.ipBlock.cidr')
                echo "    Target -->|Allow| ExternalDest[\"IP: $cidr\"]"
            fi
        done
    done
}

# Main script
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <policy.yaml>"
    exit 1
fi

if [ ! -f "$1" ]; then
    echo "Error: Policy file not found: $1"
    exit 1
fi

# Check for yq
if ! command -v yq &> /dev/null; then
    echo "Error: yq is required but not installed."
    echo "Install with: brew install yq"
    exit 1
fi

generate_mermaid "$1"
