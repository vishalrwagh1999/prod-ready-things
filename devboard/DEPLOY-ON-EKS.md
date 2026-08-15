# Deploy DevBoard on Existing EKS Cluster

This guide deploys the DevBoard application (React + Go + Postgres) into the **same EKS cluster** (`project-eks`) and **same ALB** already used by app1/app2 — just in a separate `devboard` namespace.

---

## How It Fits Into the Existing Setup

```
                        USER BROWSER
                             |
         +-------------------+-------------------+
         |                   |                   |
      /app1               /app2                  /
         |                   |                   |
         v                   v                   v
+----------------------------------------------------------+
|           AWS ALB (same existing Load Balancer)          |
|   k8s-default-demoalb-212300ed89-430070403               |
|              .us-west-2.elb.amazonaws.com                |
+----------------------------------------------------------+
         |                   |                   |
    app1-service        app2-service    devboard-frontend-service
    (default ns)        (default ns)       (devboard ns)
         |                   |                   |
       app1 pods           app2 pods      frontend pods
                                                 |
                                          backend service
                                                 |
                                          backend pods
                                                 |
                                         postgres (StatefulSet)
```

> The ALB routes `/` to DevBoard frontend. The frontend forwards `/api` calls to the Go backend internally. Postgres is internal only — never exposed outside the cluster.

---

## Prerequisites

- Existing `project-eks` cluster running
- `kubectl` configured → `aws eks update-kubeconfig --region us-west-2 --name project-eks`
- AWS Load Balancer Controller already installed (from eks-prod setup)
- Docker Hub images available: `trainwithshubham/devboard-frontend` and `trainwithshubham/devboard-backend`

---

## Step 1 — Create the Namespace

```bash
kubectl apply -f k8s/namespace.yml
```

Verify:
```bash
kubectl get namespace devboard
```

---

## Step 2 — Create the Postgres Secret (devboard-secrets)

The backend and postgres both read credentials from a Kubernetes Secret named `devboard-secrets`.

**Option A — Simple (manual secret, no AWS Secrets Manager needed):**

```bash
kubectl create secret generic devboard-secrets \
  --namespace devboard \
  --from-literal=POSTGRES_USER=devboard \
  --from-literal=POSTGRES_PASSWORD=devboard123 \
  --from-literal=POSTGRES_DB=devboard
```

**Option B — Production (AWS Secrets Manager via ExternalSecret):**

First create the secret in AWS:
```bash
aws secretsmanager create-secret \
  --name devboard/postgres \
  --secret-string '{"username":"devboard","password":"devboard123","dbname":"devboard"}'
```

Then apply the ExternalSecret (requires External Secrets Operator installed):
```bash
kubectl apply -f k8s/external-secret.yml
```

> For a quick deploy, use Option A. Option B is for production.

---

## Step 3 — Deploy Postgres

```bash
# ConfigMap with schema + seed data
kubectl apply -f k8s/postgres-init.yml

# StatefulSet + Headless Service
kubectl apply -f k8s/postgres-statefulset.yml
kubectl apply -f k8s/postgres-service.yml
```

Wait for Postgres to be ready:
```bash
kubectl get pods -n devboard -w
# Wait until postgres-statefulset-0 shows Running
```

> Note: Postgres uses `storageClassName: gp3` — make sure the `aws-ebs-csi-driver` addon is installed on your cluster (it is, if you used the `eks-prod` Terraform).

---

## Step 4 — Deploy Backend

```bash
kubectl apply -f k8s/backend-deployment.yml
kubectl apply -f k8s/backend-service.yml
```

Verify backend is healthy:
```bash
kubectl get pods -n devboard
kubectl logs -n devboard -l app=devboard-backend --tail=20
```

---

## Step 5 — Deploy Frontend

```bash
kubectl apply -f k8s/frontend-deployment.yml
kubectl apply -f k8s/frontend-service.yml
```

---

## Step 6 — Create the Ingress (Share the Existing ALB)

Create a new file `k8s/ingress.yml` with the content below.
This adds DevBoard to the **same ALB** already serving app1 and app2:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: devboard-ingress
  namespace: devboard
  annotations:
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
    alb.ingress.kubernetes.io/group.name: shared-alb        # <-- this is the key line
    alb.ingress.kubernetes.io/group.order: "10"
spec:
  ingressClassName: alb
  rules:
  - http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: devboard-frontend-service
            port:
              number: 8080
```

> `alb.ingress.kubernetes.io/group.name: shared-alb` — this tells AWS LBC to reuse the **same ALB** instead of creating a new one. You must also add this same annotation to your existing `app1/app2` ingress.

Apply it:
```bash
kubectl apply -f k8s/ingress.yml
```

---

## Step 6b — Update Existing app1/app2 Ingress to Join the Same Group

Edit your existing `ingress.yml` in `eks-prod` or wherever app1/app2 ingress is defined and add:

```yaml
metadata:
  annotations:
    alb.ingress.kubernetes.io/group.name: shared-alb    # add this
    alb.ingress.kubernetes.io/group.order: "1"          # add this
```

Re-apply:
```bash
kubectl apply -f <path-to-app1-app2-ingress.yml>
```

---

## Step 7 — Verify Everything

```bash
# Check all pods are running
kubectl get pods -n devboard

# Check ingress got an ADDRESS
kubectl get ingress -n devboard

# Check services
kubectl get svc -n devboard
```

Expected pods output:
```
NAME                                        READY   STATUS    
devboard-frontend-deployment-xxxx           1/1     Running   
devboard-backend-deployment-xxxx            1/1     Running   
postgres-statefulset-0                      1/1     Running   
```

---

## Step 8 — Access the Application

Once the ingress ADDRESS appears (same ALB DNS as app1/app2):

```
http://k8s-default-demoalb-212300ed89-430070403.us-west-2.elb.amazonaws.com/
```

| Path | Goes To |
|------|---------|
| `/` | DevBoard React frontend |
| `/api/*` | Go backend (handled internally by frontend proxy) |
| `/app1` | App1 (existing) |
| `/app2` | App2 (existing) |

---

## All Apply Commands in Order

```bash
kubectl apply -f k8s/namespace.yml
kubectl apply -f k8s/postgres-init.yml
kubectl apply -f k8s/postgres-statefulset.yml
kubectl apply -f k8s/postgres-service.yml
kubectl apply -f k8s/backend-deployment.yml
kubectl apply -f k8s/backend-service.yml
kubectl apply -f k8s/frontend-deployment.yml
kubectl apply -f k8s/frontend-service.yml
kubectl apply -f k8s/ingress.yml
```

---

## Teardown

```bash
kubectl delete namespace devboard
# This deletes all resources inside devboard namespace including PVCs
```
