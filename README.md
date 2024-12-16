# Kubernetes Network Policy Examples

This repository contains comprehensive examples and visual explanations of Kubernetes Network Policies. It's designed to help developers and DevOps engineers understand and implement network policies in Kubernetes clusters.

## Contents

### Documentation
- [Network Policy Examples with Images](network-policy-flows-with-images.md) - Detailed examples with visual diagrams
- [Network Policy Examples (YAML)](network-policy-examples.yaml) - Raw YAML configurations
- [Network Policy Limitations](network-policy-limitations.md) - Understanding the limitations and considerations

### Directory Structure
```
.
├── README.md
├── images/              # Generated diagram images
│   └── README.md       # Image maintenance documentation
├── scripts/            # Utility scripts
│   └── update_diagrams.sh
└── network-policy-*.md # Documentation files
```

## Prerequisites
To work with the diagram generation:
- Node.js
- Mermaid CLI (`npm install -g @mermaid-js/mermaid-cli`)

## Usage

### Viewing the Documentation
1. Start with [network-policy-flows-with-images.md](network-policy-flows-with-images.md) for a comprehensive guide
2. Each example includes:
   - Visual diagram
   - Purpose explanation
   - YAML configuration
   - Implementation notes

### Updating Diagrams
```bash
cd scripts
./update_diagrams.sh
```

## Network Policy Examples Included

1. **Deny All Ingress Traffic**
   - Basic deny-all policy
   - Foundation for zero-trust networking

2. **Namespace-Specific Access**
   - Allow traffic from specific namespaces
   - Cross-namespace communication control

3. **Multi-Port Multi-Source**
   - Complex access patterns
   - Multiple source and port configurations

4. **External Egress Control**
   - Control outbound traffic
   - IP block management

5. **Complex Ingress-Egress**
   - Combined ingress and egress rules
   - Database access patterns

6. **Label-Based Selection**
   - Advanced label selectors
   - Complex matching criteria

7. **Same Namespace Communication**
   - Intra-namespace traffic control
   - Development environment patterns

8. **Mixed Internal-External**
   - Combined internal and external access
   - Public service patterns

## Contributing
Contributions are welcome! Please feel free to submit a Pull Request.

## License
This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
