# Network Policy Visualization Tools and Techniques

This guide covers various tools and methods to visualize Kubernetes Network Policies, making them easier to understand and debug.

## Table of Contents
- [Online Tools](#online-tools)
- [CLI Tools](#cli-tools)
- [Graph Visualization](#graph-visualization)
- [Integration Tools](#integration-tools)
- [Custom Visualization Scripts](#custom-visualization-scripts)

## Online Tools

### 1. Cilium Network Policy Editor
- **URL**: https://editor.cilium.io/
- **Features**:
  - Visual policy editor
  - Real-time YAML generation
  - Policy validation
  - Interactive diagram
- **Usage**:
  ```bash
  # Export your policy
  kubectl get networkpolicy -o yaml > policy.yaml
  # Upload to editor.cilium.io
  ```

### 2. Network Policy Viewer
- **URL**: https://orca.tufin.io/netpol/
- **Features**:
  - Visual representation of policies
  - Policy simulation
  - Conflict detection
  - Compliance checking

### 3. KubeBuilder Network Policy Viewer
- **URL**: https://kubernetes.io/docs/concepts/services-networking/network-policies/
- **Features**:
  - Official Kubernetes documentation
  - Interactive examples
  - Visual explanations

## CLI Tools

### 1. kubectl-netpol
```bash
# Installation
kubectl krew install np-viewer

# Usage
kubectl np-viewer

# Generate graph
kubectl np-viewer graph > network-policy.dot
dot -Tpng network-policy.dot -o network-policy.png
```

### 2. Popeye Network Policy Analyzer
```bash
# Installation
brew install derailed/popeye/popeye

# Usage
popeye -n your-namespace
```

### 3. kubenetwork
```bash
# Installation
go get github.com/networkop/kubenetwork

# Usage
kubenetwork visualize
```

## Graph Visualization

### 1. Using Graphviz
```bash
# Installation
brew install graphviz

# Generate DOT file
cat <<EOF > network-policy.dot
digraph netpol {
  rankdir=LR;
  node [shape=box];
  
  # Pods
  "frontend" [label="Frontend\napp=frontend"];
  "backend" [label="Backend\napp=backend"];
  "database" [label="Database\napp=db"];
  
  # Policies
  "frontend" -> "backend" [label="allow\nport: 8080"];
  "backend" -> "database" [label="allow\nport: 5432"];
}
EOF

# Generate PNG
dot -Tpng network-policy.dot -o network-policy.png
```

### 2. Using D3.js Visualization
Create an HTML file to visualize policies interactively:

```html
<!DOCTYPE html>
<html>
<head>
    <title>Network Policy Visualizer</title>
    <script src="https://d3js.org/d3.v7.min.js"></script>
    <style>
        .node { fill: #69b3a2; }
        .link { stroke: #999; }
        .label { font-size: 12px; }
    </style>
</head>
<body>
    <div id="graph"></div>
    <script>
        // D3.js visualization code
        const data = {
            nodes: [
                { id: "frontend", group: 1 },
                { id: "backend", group: 2 },
                { id: "database", group: 3 }
            ],
            links: [
                { source: "frontend", target: "backend", value: 1 },
                { source: "backend", target: "database", value: 1 }
            ]
        };

        // D3 force simulation setup
        const width = 800;
        const height = 600;

        const svg = d3.select("#graph")
            .append("svg")
            .attr("width", width)
            .attr("height", height);

        // Add visualization code here
    </script>
</body>
</html>
```

## Integration Tools

### 1. Lens IDE Integration
- Install Lens IDE
- Add Network Policy visualization plugin
- View policies in GUI

### 2. K9s Integration
```bash
# Installation
brew install k9s

# Usage
k9s
# Press Shift+:
# Type 'netpol'
```

### 3. Octant Visualization
```bash
# Installation
brew install octant

# Usage
octant
# Navigate to Network Policies
```

## Custom Visualization Scripts

### 1. Policy to Mermaid Converter
See the included script: `scripts/policy-to-mermaid.sh`

### 2. Interactive Policy Viewer
See the included script: `scripts/interactive-policy-viewer.sh`

### 3. Policy Graph Generator
See the included script: `scripts/generate-policy-graph.sh`

## Best Practices for Visualization

### 1. Color Coding
- Green: Allowed traffic
- Red: Denied traffic
- Yellow: Conditional access
- Blue: External traffic

### 2. Layout Guidelines
- Left to right flow
- Group by namespace
- Show labels clearly
- Include port information

### 3. Documentation
- Include legend
- Show policy names
- Document exceptions
- Include timestamps

## Maintenance and Updates

### Keeping Visualizations Current
```bash
# Add to your CI/CD pipeline
./scripts/update-policy-diagrams.sh

# Generate documentation
./scripts/generate-policy-docs.sh
```

### Version Control
```bash
# Save visualizations
git add diagrams/
git commit -m "Update network policy visualizations"
```

## Additional Resources
- [Kubernetes Network Policy Documentation](https://kubernetes.io/docs/concepts/services-networking/network-policies/)
- [Cilium Network Policy Editor](https://editor.cilium.io/)
- [Network Policy Viewer](https://orca.tufin.io/netpol/)
- [Graphviz Documentation](https://graphviz.org/documentation/)
