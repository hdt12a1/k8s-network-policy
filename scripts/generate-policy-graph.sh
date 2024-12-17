#!/bin/bash

# Generate network policy graphs using Graphviz
# This script creates visual representations of network policies

# Check prerequisites
check_prerequisites() {
    local missing_deps=0
    
    if ! command -v dot &> /dev/null; then
        echo "Error: graphviz is required but not installed."
        echo "Install with: brew install graphviz"
        missing_deps=1
    fi
    
    if ! command -v kubectl &> /dev/null; then
        echo "Error: kubectl is required but not installed."
        missing_deps=1
    fi
    
    if [ $missing_deps -eq 1 ]; then
        exit 1
    fi
}

# Generate DOT file for a single policy
generate_policy_dot() {
    local policy_name=$1
    local namespace=$2
    local output_file=$3
    
    echo "digraph \"$policy_name\" {" > "$output_file"
    echo "  rankdir=LR;" >> "$output_file"
    echo "  node [shape=box, style=rounded];" >> "$output_file"
    
    # Get policy details
    kubectl get networkpolicy "$policy_name" -n "$namespace" -o yaml | \
    while IFS= read -r line; do
        if [[ $line =~ "podSelector:" ]]; then
            # Extract pod selector labels
            local labels=$(kubectl get networkpolicy "$policy_name" -n "$namespace" -o jsonpath='{.spec.podSelector.matchLabels}')
            echo "  \"target\" [label=\"Target Pods\\n$labels\", color=blue];" >> "$output_file"
        fi
        
        if [[ $line =~ "ingress:" ]]; then
            process_ingress "$policy_name" "$namespace" "$output_file"
        fi
        
        if [[ $line =~ "egress:" ]]; then
            process_egress "$policy_name" "$namespace" "$output_file"
        fi
    done
    
    echo "}" >> "$output_file"
}

# Process ingress rules
process_ingress() {
    local policy_name=$1
    local namespace=$2
    local output_file=$3
    
    kubectl get networkpolicy "$policy_name" -n "$namespace" -o jsonpath='{.spec.ingress[*]}' | \
    while IFS= read -r rule; do
        # Process from rules
        echo "$rule" | jq -r '.from[]?' | while read -r from; do
            if [[ $from =~ "podSelector" ]]; then
                local pod_labels=$(echo "$from" | jq -r '.podSelector.matchLabels')
                echo "  \"pod_$pod_labels\" [label=\"Pod\\n$pod_labels\"];" >> "$output_file"
                echo "  \"pod_$pod_labels\" -> \"target\" [label=\"allow\"];" >> "$output_file"
            fi
            
            if [[ $from =~ "namespaceSelector" ]]; then
                local ns_labels=$(echo "$from" | jq -r '.namespaceSelector.matchLabels')
                echo "  \"ns_$ns_labels\" [label=\"Namespace\\n$ns_labels\"];" >> "$output_file"
                echo "  \"ns_$ns_labels\" -> \"target\" [label=\"allow\"];" >> "$output_file"
            fi
        done
    done
}

# Process egress rules
process_egress() {
    local policy_name=$1
    local namespace=$2
    local output_file=$3
    
    kubectl get networkpolicy "$policy_name" -n "$namespace" -o jsonpath='{.spec.egress[*]}' | \
    while IFS= read -r rule; do
        # Process to rules
        echo "$rule" | jq -r '.to[]?' | while read -r to; do
            if [[ $to =~ "podSelector" ]]; then
                local pod_labels=$(echo "$to" | jq -r '.podSelector.matchLabels')
                echo "  \"dest_pod_$pod_labels\" [label=\"Pod\\n$pod_labels\"];" >> "$output_file"
                echo "  \"target\" -> \"dest_pod_$pod_labels\" [label=\"allow\"];" >> "$output_file"
            fi
            
            if [[ $to =~ "namespaceSelector" ]]; then
                local ns_labels=$(echo "$to" | jq -r '.namespaceSelector.matchLabels')
                echo "  \"dest_ns_$ns_labels\" [label=\"Namespace\\n$ns_labels\"];" >> "$output_file"
                echo "  \"target\" -> \"dest_ns_$ns_labels\" [label=\"allow\"];" >> "$output_file"
            fi
        done
    done
}

# Generate graph for all policies in a namespace
generate_namespace_graph() {
    local namespace=$1
    local output_dir=$2
    
    mkdir -p "$output_dir"
    
    # Get all network policies in namespace
    kubectl get networkpolicy -n "$namespace" -o name | while read -r policy; do
        local policy_name=$(basename "$policy")
        local dot_file="$output_dir/${policy_name}.dot"
        local png_file="$output_dir/${policy_name}.png"
        
        echo "Generating graph for policy: $policy_name"
        generate_policy_dot "$policy_name" "$namespace" "$dot_file"
        dot -Tpng "$dot_file" -o "$png_file"
        
        echo "Generated: $png_file"
    done
}

# Main script
main() {
    check_prerequisites
    
    local namespace=$1
    local output_dir=${2:-"network-policy-graphs"}
    
    if [ -z "$namespace" ]; then
        echo "Usage: $0 <namespace> [output-directory]"
        exit 1
    fi
    
    generate_namespace_graph "$namespace" "$output_dir"
}

main "$@"
