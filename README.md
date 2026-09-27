# Pet Clinic Project Overview

## Repository Layout

```
.
├── spring-petclinic-microservices/   # Java/Spring microservices application
│   ├── README.md                     # Application start‑up guide
│   ├── pom.xml                       # Maven aggregator with modules for each service
│   └── <service-modules>             # customers, vets, visits, genai, admin, gateway, config, discovery
│
├── petclinic-platform/               # AWS infrastructure‑as‑code
│   ├── terraform/                    # Terraform root modules (dev, prod) and reusable modules
│   ├── k8s/                          # Base Kubernetes manifests and environment overlays
│   ├── helm/                         # Generic Helm chart shared by all services
│   ├── helm-values/                  # Service‑specific and env‑specific value files
│   ├── docs/                         # Architecture docs, runbooks, ADRs
│   └── .github/workflows/            # CI pipelines (build, push, image‑tag update)
│
├── COMBINED-README.md               # **This file** – high‑level project overview
└── ... (tooling files, .claude settings, etc.)
```

---

## Microservices Architecture (Spring Petclinic)

The application is split into eight independent Spring Boot services, each packaged as a separate Docker image and deployed behind a **Spring Cloud Gateway** API gateway.

| Service | Port | Primary Responsibility | Dependencies |
|--------|------|------------------------|--------------|
| **Config Server** | 8888 | Centralised configuration repository (Git‑backed) | – |
| **Discovery Server** | 8761 | Eureka service registry – enables dynamic discovery of all services | Config Server |
| **API Gateway** | 8080 | Routes external HTTP requests to backend services; applies circuit‑breaker and fallback logic via Resilience4j | Config Server, Discovery Server |
| **Customers Service** | 8081 | CRUD for owners and pets | Config Server, Discovery Server, (optional) MySQL |
| **Visits Service** | 8082 | CRUD for pet visit records | Config Server, Discovery Server, (optional) MySQL |
| **Vets Service** | 8083 | Veterinarian data, includes a Caffeine cache for fast look‑ups | Config Server, Discovery Server |
| **GenAI Service** | 8084 | Chat‑bot interface built with Spring AI; uses OpenAI or Azure OpenAI | Config Server, Discovery Server, optional external LLM credentials |
| **Admin Server** | 9090 | Spring Boot Admin UI for monitoring all services | Config Server, Discovery Server |

### Communication & Resilience
- **Service discovery** is handled by Eureka; each service registers itself on startup and obtains the registry address from the Config Server.
- **API Gateway** uses Spring Cloud Gateway routes defined in `application.yml` and adds **Resilience4j** circuit‑breaker patterns with fall‑back methods for each downstream call.
- **Distributed tracing** is enabled via **Zipkin** (http://localhost:9411/zipkin/). All services emit OpenTelemetry spans which are correlated in the tracing UI.
- **Metrics** are instrumented with Micrometer (`@Timed` annotations) and scraped by **Prometheus**; Grafana dashboards visualise request latency, error rates, JVM stats, and custom business metrics.
- **Chaos Monkey** profile injects latency, exception, and kill‑pod assaults to test resilience automatically at startup.

---

## Platform Architecture (AWS)

The `petclinic-platform` directory contains the full production‑grade deployment stack for the microservices.

### Core AWS Resources
- **VPC** – single public subnet design (no NAT) to minimise cost for learning environments. All services are reachable via the public ALB.
- **EKS Cluster** – managed Kubernetes control plane; node groups provisioned with Graviton (ARM) `t4g.small` instances via **Karpenter** for autoscaling.
- **RDS MySQL** – single‑AZ `db.t4g.micro` instance (free‑tier eligible) used by the services that require persistence (`customers`, `visits`, `vets`). The `mysql` Spring profile activates this connection.
- **ECR** – one repository per service per environment (`petclinic-dev/<service>`, `petclinic-prod/<service>`). Images are built with multi‑arch support (`linux/arm64`).
- **Route 53 + ACM** – DNS records and TLS certificates for the public ALB that fronts the API Gateway.
- **Secrets Manager + External Secrets Operator** – secrets (DB passwords, OpenAI keys) are stored in AWS Secrets Manager and injected into the cluster at runtime.

### Observability Stack
- **Prometheus** – scrapes `/actuator/prometheus` endpoints from every service.
- **Grafana** – dashboards located in `docker/grafana/dashboards/grafana-petclinic-dashboard.json`.
- **Zipkin** – collects distributed traces; deployed as a side‑car in the cluster.
- **Fluent Bit** – ships container logs to CloudWatch Logs for centralised retention.

### Deployment Pipeline
1. **Terraform** – `terraform/environments/{dev,prod}` provision the VPC, EKS, RDS, IAM, Secrets, and networking. State is stored in an S3 bucket with DynamoDB locking.
2. **GitHub Actions** – CI builds Docker images (`./mvnw clean install -P buildDocker`), pushes to ECR, and updates the corresponding `helm-values/<service>.yaml` with the new image SHA.
3. **ArgoCD** – watches the Git repository. For each service‑environment pair there is an `Application` CR; ArgoCD automatically syncs **dev** (auto‑sync) and requires manual approval for **prod**.
4. **Helm** – the generic chart (`helm/petclinic-service/`) renders the Kubernetes resources. Service‑specific values (environment variables, secrets, replica counts) are supplied via `helm-values/<service>.yaml` and merged with `helm-values/<env>.yaml`.

### Security & Governance (Non‑Negotiable Rules)
- No secrets are checked into the repository; all secret material lives in AWS Secrets Manager.
- All S3 buckets have `BlockPublicAcls` and `IgnorePublicAcls` enabled.
- Security groups restrict inbound traffic to the ALB (80/443) and to the EKS nodes only from the ALB.
- IAM policies follow the principle of least privilege – each module creates a dedicated role with scoped permissions.
- Terraform `destroy` operations are blocked by a pre‑tool hook; any destructive action must be explicitly approved.

---

## Getting Started

### Application (Local Development)
See the `spring-petclinic-microservices/README.md` for detailed steps to run the services with Maven or Docker Compose.

### Platform (AWS Deployment)
1. Initialise remote state (once): `cd petclinic-platform/scripts && ./bootstrap-state.sh dev`.
2. Run Terraform plan & apply in the desired environment (`dev` or `prod`).
3. Build Docker images and push to ECR (`./mvnw clean install -P buildDocker`).
4. Let the CI pipeline update Helm values, then sync via ArgoCD (`argocd app sync <service>-dev`).

---

## Contributing
Both sub‑projects have their own `CONTRIBUTING.md`. In short:
- Fork the repo, create a feature branch.
- Run `./mvnw verify` for Java changes and `terraform fmt/validate` + `helm lint` for infra changes before committing.
- Open a Pull Request; CI will automatically run tests, lint, and security scans.

---

## License
Apache License 2.0 – see the `LICENSE` file at the repository root.

---

*Generated by Claude Code*