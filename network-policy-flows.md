# Network Policy Flow Diagrams

## Example 1: Deny All Ingress Traffic
### Flow Diagram
```mermaid
graph LR
    subgraph production-namespace
        A[External Traffic] -. ❌ Blocked .-> B[Any Pod]
        C[Other Namespace Pods] -. ❌ Blocked .-> B
        D[Same Namespace Pods] -. ❌ Blocked .-> B
    end
    style B fill:#f9f,stroke:#333
```

### Policy Code
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-ingress
  namespace: production
spec:
  podSelector: {}  # Empty selector means select all pods
  policyTypes:
  - Ingress      # Only applying to incoming traffic
```

## Example 2: Allow Traffic from Specific Namespace
### Flow Diagram
```mermaid
graph LR
    subgraph development-namespace
        A[Dev Pods]
    end
    subgraph production-namespace
        B[Web Pods<br/>app: web]
    end
    A -->|✅ Allowed| B
    C[Other Namespace Pods] -. ❌ Blocked .-> B
```

### Policy Code
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-from-dev-namespace
  namespace: production
spec:
  podSelector:           # This policy applies to pods with label app: web
    matchLabels:
      app: web
  policyTypes:
  - Ingress
  ingress:
  - from:
    - namespaceSelector:    # Select source namespace based on labels
        matchLabels:
          environment: development
```

## Example 3: Multi-Port Multi-Source
### Flow Diagram
```mermaid
graph LR
    subgraph production-namespace
        A[Frontend Pods<br/>role: frontend] -->|✅ Port 8080, 443| C[API Pods<br/>app: api]
        B[Monitoring Pods<br/>role: monitoring] -->|✅ Port 8080, 443| C
        D[Other Pods] -. ❌ Blocked .-> C
    end
```

### Policy Code
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: multi-port-multi-source
  namespace: production
spec:
  podSelector:
    matchLabels:
      app: api          # Applies to API pods
  policyTypes:
  - Ingress
  ingress:
  - from:              # Multiple source pods can access
    - podSelector:
        matchLabels:
          role: frontend    # Allow frontend pods
    - podSelector:
        matchLabels:
          role: monitoring  # Allow monitoring pods
    ports:             # Define allowed ports
    - protocol: TCP
      port: 8080      # Main API port
    - protocol: TCP
      port: 443       # HTTPS port
```

## Example 4: External Egress Control
### Flow Diagram
```mermaid
graph LR
    subgraph production-namespace
        A[Backend Pods<br/>app: backend]
    end
    subgraph External-IPs
        B[10.0.0.0/24<br/>Allowed Range]
        C[10.0.0.12/32<br/>Blocked IP]
    end
    A -->|✅ Port 443| B
    A -. ❌ Blocked .-> C
```

### Policy Code
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-external-egress
  namespace: production
spec:
  podSelector:
    matchLabels:
      app: backend     # Applies to backend pods
  policyTypes:
  - Egress            # Controls outgoing traffic
  egress:
  - to:
    - ipBlock:
        cidr: 10.0.0.0/24           # Allow traffic to this IP range
        except:
        - 10.0.0.12/32              # Except this specific IP
    ports:
    - protocol: TCP
      port: 443                     # HTTPS traffic only
```

## Example 5: Complex Policy with Ingress and Egress
### Flow Diagram
```mermaid
graph TD
    subgraph production-namespace
        A[Backend Pods<br/>role: backend] -->|✅ Port 5432| B[Database Pods<br/>app: database]
        C[Other Pods] -. ❌ Blocked .-> B
    end
    subgraph monitoring-namespace
        D[Monitoring Service]
    end
    B -->|✅ Port 9090| D
```

### Policy Code
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: complex-policy
  namespace: production
spec:
  podSelector:
    matchLabels:
      app: database    # Applies to database pods
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - namespaceSelector:    # Must be in production namespace
        matchLabels:
          environment: production
      podSelector:          # AND must be a backend pod
        matchLabels:
          role: backend
    ports:
    - protocol: TCP
      port: 5432           # PostgreSQL port
  egress:
  - to:
    - namespaceSelector:    # Allow sending metrics to monitoring
        matchLabels:
          environment: monitoring
    ports:
    - protocol: TCP
      port: 9090           # Prometheus port
```

## Example 6: Multi-Label Selector
### Flow Diagram
```mermaid
graph LR
    subgraph production-namespace
        A[Monitoring Pods<br/>role: monitoring] -->|✅ Port 80| C[Web Pods<br/>app: web<br/>tier: frontend]
        B[Logging Pods<br/>role: logging] -->|✅ Port 80| C
        D[Other Pods] -. ❌ Blocked .-> C
    end
```

### Policy Code
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: multi-label-selector
  namespace: production
spec:
  podSelector:
    matchLabels:
      app: web
      tier: frontend    # Pods must have both labels
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchExpressions:   # More flexible than matchLabels
        - key: role
          operator: In     # Allows multiple values
          values: ["monitoring", "logging"]
    ports:
    - protocol: TCP
      port: 80
```

## Example 7: Allow Same Namespace
### Flow Diagram
```mermaid
graph LR
    subgraph production-namespace
        A[Pod 1] -->|✅ All Traffic| B[Pod 2]
        B -->|✅ All Traffic| C[Pod 3]
        C -->|✅ All Traffic| A
    end
    subgraph other-namespace
        D[External Pod] -. ❌ Blocked .-> A
    end
```

### Policy Code
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-same-namespace
  namespace: production
spec:
  podSelector: {}      # Applies to all pods in namespace
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector: {}  # Allow from all pods in same namespace
```

## Example 8: External and Internal Traffic
### Flow Diagram
```mermaid
graph TD
    subgraph production-namespace
        A[Frontend Pods<br/>role: frontend] -->|✅ Port 80| B[Web Pods<br/>app: web]
    end
    subgraph External-Traffic
        C[Allowed IPs<br/>172.17.0.0/16] -->|✅ Port 80| B
        D[Blocked Subnet<br/>172.17.1.0/24] -. ❌ Blocked .-> B
    end
```

### Policy Code
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-external-and-internal
  namespace: production
spec:
  podSelector:
    matchLabels:
      app: web        # Applies to web pods
  policyTypes:
  - Ingress
  ingress:
  - from:
    - ipBlock:        # Allow external IPs
        cidr: 172.17.0.0/16
        except:
        - 172.17.1.0/24    # Blocked subnet
    - podSelector:         # Allow internal pods
        matchLabels:
          role: frontend
    ports:
    - protocol: TCP
      port: 80            # HTTP traffic
```

## Legend
```mermaid
graph LR
    A -->|✅ Allowed Traffic| B
    C -. ❌ Blocked Traffic .-> D
    style A fill:#90EE90
    style B fill:#90EE90
    style C fill:#FFB6C1
    style D fill:#FFB6C1
```

## Notes
- Green boxes represent allowed sources/destinations
- Red dotted lines represent blocked traffic
- Solid lines represent allowed traffic
- Labels on arrows show allowed ports
- Each diagram represents the traffic flow after the network policy is applied
- Pods are labeled with their selector labels for clarity
- YAML code shows the exact implementation for each scenario
