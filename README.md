# prod-ready-things

A mono-repo of production-ready DevOps projects covering AWS, Kubernetes, Terraform, CI/CD, and DevSecOps.

---

## Repository Structure

### 1. `AI-BankApp-DevOps/`
A production-grade **DevSecOps Banking Application** built with Java 21 + Spring Boot 3, deployed on AWS EC2 via Docker.
- Full 9-gate DevSecOps CI/CD pipeline using GitHub Actions (Gitleaks, Semgrep, OWASP, Trivy, ZAP)
- Keyless AWS authentication via OIDC (no static credentials)
- Secrets managed via AWS Secrets Manager
- AI integration using Ollama (TinyLlama) on a dedicated EC2 tier
- Container images stored in Amazon ECR

---

### 2. `devboard/`
A full-stack **project management dashboard** (React + Go + Postgres) with a complete DevSecOps + GitOps pipeline.
- Three-tier architecture: React frontend → Go API backend → Postgres database
- Dockerized with Docker Compose for local development
- CI/CD via GitHub Actions: security gates → build → push to Docker Hub → GitOps bump
- Kubernetes deployment on EKS using Terraform, Argo CD, Helm, and Gateway API
- Observability with OpenTelemetry tracing across all tiers
- Credentials managed via AWS Secrets Manager

---

### 3. `eks-prod/`
Terraform code to provision a **production-grade Amazon EKS cluster** with a dedicated VPC.
- Multi-AZ VPC with public/private subnets, NAT Gateway, and S3 VPC endpoint
- EKS managed node group with IMDSv2, encrypted EBS, and auto-scaling
- OIDC provider for IRSA (IAM Roles for Service Accounts)
- Core add-ons: `vpc-cni`, `coredns`, `kube-proxy`, `aws-ebs-csi-driver`
- AWS Load Balancer Controller setup with Helm + IRSA

---

### 4. `votingApp/`
A classic **distributed voting application** demonstrating multi-container Docker architecture.
- Frontend vote app (Python) + Redis queue + .NET worker + Postgres + Node.js results app
- Supports Docker Compose, Docker Swarm, and Kubernetes deployments
- Includes Azure Pipelines CI/CD configurations
- Kubernetes manifests available in `k8s-specifications/`
