# Network Policy Diagrams

This folder contains all the network policy flow diagrams used in the documentation.

## Generated Files
- `policy1.png` - Deny all ingress traffic diagram
- `policy2.png` - Allow traffic from specific namespace
- `policy3.png` - Multi-port multi-source access
- `policy4.png` - External egress control
- `policy5.png` - Complex policy with ingress and egress
- `policy6.png` - Multi-label selector
- `policy7.png` - Allow same namespace
- `policy8.png` - External and internal traffic
- `policy9.png` - Diagram legend

## Image Specifications
- Format: PNG
- Background: Transparent
- Generated using: Mermaid CLI (mmdc)

## Maintenance Instructions
1. To update diagrams:
   ```bash
   cd ../scripts
   ./update_diagrams.sh
   ```

2. The script will:
   - Extract Mermaid diagrams from network-policy-flows.md
   - Generate new PNG files
   - Preserve existing file names

3. After updating:
   - Verify the quality of new images
   - Check that all diagrams are properly rendered
   - Commit both the markdown and generated images

## Notes
- Images are automatically numbered based on their order in the markdown
- All images have transparent backgrounds for better documentation integration
- Original Mermaid source is preserved in the markdown files
