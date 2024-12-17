# Debugging Kubernetes Network Policies

This guide provides comprehensive steps and tools for debugging Network Policies in Kubernetes.

## Table of Contents
- [Common Issues](#common-issues)
- [Debugging Tools](#debugging-tools)
- [Debugging Steps](#debugging-steps)
- [Example Scenarios](#example-scenarios)
- [Best Practices](#best-practices)
- [Checking Network Plugin (CNI) in EKS](#checking-network-plugin-cni-in-eks)
- [Network Policy Logging and Traffic Analysis](#network-policy-logging-and-traffic-analysis)
- [AWS VPC CNI Network Policy Debugging](#aws-vpc-cni-network-policy-debugging)

## Common Issues

### 1. Policy Not Being Applied
- Network plugin doesn't support Network Policies
- Policy is in wrong namespace
- Label selectors don't match pods
- CNI plugin not properly configured

### 2. Unexpected Blocking
- Multiple policies affecting the same pod
- Default deny policy blocking traffic
- Missing ingress/egress rules
- Incorrect CIDR ranges

### 3. Performance Issues
- Too many network policies
- Complex label selectors
- Large number of rules
- Inefficient policy design

## Debugging Tools

### 1. kubectl Commands
```bash
# Check if network policy exists
kubectl get networkpolicy -n <namespace>

# Describe network policy
kubectl describe networkpolicy <policy-name> -n <namespace>

# Check pod labels
kubectl get pods --show-labels -n <namespace>

# Check logs of CNI pods
kubectl logs -n kube-system -l k8s-app=calico-node
```

### 2. Network Debugging Tools
```bash
# Deploy a debug pod
kubectl run debug-pod --image=nicolaka/netshoot -it --rm -- /bin/bash

# Inside debug pod
ping <target-ip>
nc -zv <target-ip> <port>
tcpdump -i any
```

### 3. Policy Visualization
```bash
# Using kubectl-netpol plugin
kubectl netpol graph

# Using popeye for policy analysis
popeye -n <namespace>
```

## Debugging Steps

### 1. Verify CNI Configuration
```bash
# Check CNI plugin status
kubectl get pods -n kube-system | grep -i -E 'calico|weave|cilium'

# Verify CNI configuration
kubectl describe daemonset -n kube-system calico-node
```

### 2. Check Policy Configuration
```bash
# Export policy for analysis
kubectl get networkpolicy <policy-name> -n <namespace> -o yaml > policy.yaml

# Validate policy syntax
kubectl apply --dry-run=client -f policy.yaml
```

### 3. Test Connectivity
```bash
# Create test pods
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: test-pod
  labels:
    app: network-test
spec:
  containers:
  - name: busybox
    image: busybox
    command: ['sh', '-c', 'while true; do sleep 3600; done']
EOF

# Test connectivity
kubectl exec -it test-pod -- wget -qO- --timeout=2 http://service-name
```

## Example Scenarios

### Scenario 1: Policy Not Blocking Traffic
1. Check if the policy is being applied:
```bash
kubectl get networkpolicy <policy-name> -n <namespace> -o yaml
```

2. Verify pod labels match:
```bash
kubectl get pods -n <namespace> --show-labels
```

3. Test with a temporary deny-all policy:
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
```

### Scenario 2: Debugging Cross-Namespace Communication
1. Check namespace labels:
```bash
kubectl get namespace --show-labels
```

2. Verify namespace selector:
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-from-namespace
spec:
  podSelector: {}
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          purpose: test
```

3. Test communication:
```bash
# From source namespace
kubectl exec -n source-ns test-pod -- curl http://service.target-ns
```

## Best Practices

### 1. Policy Testing
- Start with logging policies before enforcing
- Use test namespaces
- Create test pods with different labels
- Document expected behavior

### 2. Monitoring
```bash
# Monitor policy events
kubectl get events -n <namespace> --field-selector type=Warning

# Check CNI metrics
kubectl -n kube-system port-forward ds/calico-node 9091:9091
```

### 3. Troubleshooting Checklist
- [ ] Verify CNI plugin supports Network Policies
- [ ] Check pod and namespace labels
- [ ] Validate policy syntax
- [ ] Test with simple policies first
- [ ] Monitor CNI logs
- [ ] Use debug pods for testing
- [ ] Document policy changes

### 4. Debug Commands Reference
```bash
# Check pod networking
kubectl exec -it <pod-name> -- ip addr
kubectl exec -it <pod-name> -- netstat -nltp

# DNS debugging
kubectl exec -it <pod-name> -- nslookup kubernetes.default

# Traffic analysis
kubectl exec -it <pod-name> -- tcpdump -i any port <port-number>
```

## Network Policy Logging and Traffic Analysis

### Method 1: Using CNI Logs
Depending on your CNI plugin, you can view network policy decisions in the CNI logs:

```bash
# For AWS VPC CNI
kubectl logs -n kube-system -l k8s-app=aws-node --tail=100 -f

# For Calico
kubectl logs -n calico-system -l k8s-app=calico-node --tail=100 -f

# For Cilium
kubectl logs -n kube-system -l k8s-app=cilium --tail=100 -f
```

### Method 2: Using tcpdump
You can use tcpdump inside the pod to capture traffic:

```bash
# Install tcpdump in the pod (if not already present)
kubectl exec -it <pod-name> -- apt-get update && apt-get install -y tcpdump

# Capture traffic
kubectl exec -it <pod-name> -- tcpdump -nn -i any

# Capture specific port traffic
kubectl exec -it <pod-name> -- tcpdump -nn -i any port <port-number>
```

### Method 3: Using Network Policy Audit Logging (Calico)
If using Calico, you can enable audit logging:

```yaml
apiVersion: projectcalico.org/v3
kind: FelixConfiguration
metadata:
  name: default
spec:
  logSeverityScreen: Info
  policyLogPrefix: "Policy denied: "
```

### Method 4: Testing Connectivity
Use test pods to verify network policies:

```bash
# Create a test pod
kubectl run nettest --image=nicolaka/netshoot -it --rm -- bash

# Test connectivity from inside the pod
curl -v telnet://<target-service>:<port>
nc -zv <target-pod-ip> <port>
```

### Common Log Patterns

1. **Allowed Traffic:**
   ```
   Policy allowed packet: <source> -> <destination>
   ```

2. **Denied Traffic:**
   ```
   Policy denied packet: <source> -> <destination>
   ```

3. **Connection Timeouts:**
   ```
   connect: Connection timed out
   ```

### Debugging Tips

1. **Enable Debug Logging:**
   - For most CNI plugins, you can increase log verbosity
   - Look for environment variables like `FELIX_LOGSEVERITYSCREEN=debug` (Calico)
   - Check CNI plugin documentation for specific debug flags

2. **Use Label Selectors:**
   ```bash
   # View logs from specific pods based on labels
   kubectl logs -l app=myapp -n mynamespace --tail=100 -f
   ```

3. **Correlate Timestamps:**
   - When debugging, note the exact time of the connection attempt
   - Look for corresponding entries in CNI logs
   - Use `kubectl get events` to check for related events

## AWS VPC CNI Network Policy Debugging

### Viewing Network Policy Logs

AWS VPC CNI uses `kube-proxy` and AWS Security Groups for network policy enforcement. To debug network policies:

1. **Check AWS VPC CNI Logs**:
```bash
# View logs from aws-node daemonset
kubectl logs -n kube-system -l k8s-app=aws-node --tail=100 -f

# View logs from a specific aws-node pod
kubectl get pods -n kube-system -l k8s-app=aws-node
kubectl logs -n kube-system <aws-node-pod-name> -f
```

2. **Enable Debug Logging**:
```bash
# Edit aws-node daemonset to enable debug logging
kubectl set env daemonset aws-node -n kube-system ENABLE_POD_ENI=true AWS_VPC_K8S_CNI_LOGLEVEL=DEBUG

# For more detailed networking logs
kubectl set env daemonset aws-node -n kube-system ADDITIONAL_ENI_TAGS="{\"NetworkPolicy\": \"true\"}" AWS_VPC_K8S_CNI_EXTERNALSNAT=true
```

3. **Check Security Group Rules**:
Since AWS VPC CNI translates network policies into security group rules, check:
```bash
# Get pod's security groups
kubectl describe pod <pod-name> | grep "Security Groups"

# Get node's security groups
kubectl get nodes -o wide
aws ec2 describe-instances --instance-ids <node-instance-id> --query 'Reservations[].Instances[].SecurityGroups'
```

### Common Issues and Log Patterns

1. **Policy Not Applied**:
```
level=error msg="Failed to apply NetworkPolicy" policy=<policy-name> namespace=<namespace> error=<error-message>
```

2. **Security Group Updates**:
```
level=info msg="Updated security groups" pod=<pod-name> groups=[sg-xxx,sg-yyy]
```

3. **ENI Configuration**:
```
level=debug msg="Allocated ENI" eniID=<eni-id> ipv4Addrs=<ip-addresses>
```

### Debugging Steps for AWS VPC CNI

1. **Verify Policy Configuration**:
```bash
# Check network policies in namespace
kubectl get networkpolicies -n <namespace>

# Describe specific policy
kubectl describe networkpolicy <policy-name> -n <namespace>
```

2. **Check Pod Network Configuration**:
```bash
# Get pod's network details
kubectl get pod <pod-name> -o yaml | grep -A 5 annotations

# Check ENI attachment
kubectl exec -it <pod-name> -- ip addr show
```

3. **Test Network Connectivity**:
```bash
# Create a debug pod
kubectl run netshoot --image=nicolaka/netshoot -it --rm -- bash

# Test connectivity
nc -zv <target-pod-ip> <port>
curl -v telnet://<target-service>:<port>
```

4. **Monitor VPC Flow Logs**:
Enable VPC Flow Logs in your AWS Console to see accepted/rejected traffic at the VPC level.

### Best Practices for AWS VPC CNI Network Policies

1. **Resource Limits**:
   - Monitor the number of security groups per ENI (max 5)
   - Watch for security group rule limits
   - Monitor ENI attachment limits per instance type

2. **Performance Optimization**:
   - Use namespace selectors when possible
   - Group similar policies to reduce security group updates
   - Use CIDR blocks for external traffic rules

3. **Troubleshooting Checklist**:
   - Verify AWS VPC CNI version is up to date
   - Check node instance limits
   - Verify IAM roles have necessary permissions
   - Monitor CloudWatch metrics for CNI errors

## Checking Network Plugin (CNI) in EKS

To identify which CNI plugin your EKS cluster is using, you can use several methods:

### Method 1: Check AWS Console
1. Go to the EKS console
2. Select your cluster
3. Go to the "Add-ons" tab
4. Look for the "Amazon VPC CNI" or other CNI add-ons

### Method 2: Using kubectl
```bash
# Check pods in kube-system namespace
kubectl get pods -n kube-system | grep -i cni

# Check DaemonSets in kube-system namespace
kubectl get ds -n kube-system | grep -i cni

# View CNI configuration
kubectl describe daemonset aws-node -n kube-system
```

### Method 3: Using AWS CLI
```bash
# Get cluster add-ons
aws eks describe-addon --cluster-name <your-cluster-name> --addon-name vpc-cni

# List all add-ons
aws eks list-addons --cluster-name <your-cluster-name>
```

Common CNI plugins in EKS:
- Amazon VPC CNI (default)
- Calico
- Cilium
- Weave Net

## Common Debugging Patterns

### Pattern 1: Isolate the Problem
1. Apply minimal policy
2. Test connectivity
3. Add rules incrementally
4. Document each change

### Pattern 2: Policy Validation
1. Use dry-run
2. Test in development
3. Monitor metrics
4. Review logs

### Pattern 3: Systematic Troubleshooting
1. Check CNI status
2. Verify policy syntax
3. Test pod connectivity
4. Monitor network traffic
5. Review events and logs

## Additional Resources
- [Kubernetes Network Policy Documentation](https://kubernetes.io/docs/concepts/services-networking/network-policies/)
- [CNI Plugin Documentation](https://www.cni.dev/)
- [Network Policy Editor](https://editor.cilium.io/)
- [Network Policy Validator](https://orca.tufin.io/netpol/)
