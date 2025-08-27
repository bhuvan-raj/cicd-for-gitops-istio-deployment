# GitOps CI/CD Pipeline with Kind, Istio, and Monitoring

This project sets up a fully automated, end-to-end continuous deployment pipeline for a web application using a GitOps approach. It automates the provisioning of a Kubernetes cluster, installs core tools, and deploys a sample application with a service mesh and monitoring.

## Project Overview

The pipeline automates the entire application lifecycle, from a code change to a deployed, monitored application. It uses the following components:

  * **GitHub Actions**: The CI/CD engine that orchestrates the entire workflow.
  * **Terraform**: Manages the infrastructure as code, provisioning the cluster and installing core tools.
  * **Kind**: A lightweight Kubernetes cluster running in Docker, perfect for local CI/CD environments.
  * **Trivy**: Scans the Docker image for vulnerabilities before deployment.
  * **Istio**: The service mesh that provides traffic management, security, and observability for the application.
  * **ArgoCD**: The GitOps controller that automatically synchronizes the desired application state from the Git repository to the Kubernetes cluster.
  * **Prometheus & Grafana**: The monitoring stack for collecting and visualizing application and infrastructure metrics.

## Project Structure

The repository is organized to separate different components logically.

```
.
├── .github/workflows/
│   └── main.yaml               # GitHub Actions CI/CD workflow
├── app/
│   ├── main.py                 # Sample Python web application with metrics
│   ├── Dockerfile
│   └── requirements.txt
├── manifests/
│   └── my-app/
│       ├── deployment.yaml     # Kubernetes manifest for the app
│       ├── service.yaml        # Service to expose the app
│       └── virtual-service.yaml  # Istio rule for traffic management
├── terraform/
│   └── main.tf                 # Terraform code to provision all infrastructure
└── README.md
```

-----

## Getting Started

### Prerequisites

  * **Git**
  * **Docker Desktop** (or Docker Engine)
  * **Kind** CLI
  * **kubectl**
  * **Terraform** CLI
  * A **GitHub** account and a new, empty repository.
  * A **Docker Hub** account.
  * A **self-hosted GitHub Actions runner** with all the above tools installed.
  * A GitHub Personal Access Token (PAT) with `repo` and `workflow` scopes.
  * A Docker Hub Access Token.

### Step 1: Set Up the Repository and Code

1.  Clone your empty GitHub repository.
2.  Create the file structure as shown above and add the provided application code, Dockerfiles, and Kubernetes manifests to their respective directories.
3.  Commit and push the initial code to your repository's `main` branch.

### Step 2: Configure GitHub Actions Secrets

1.  In your GitHub repository, go to **Settings** \> **Secrets and variables** \> **Actions**.
2.  Add the following repository secrets:
      * `DOCKERHUB_USERNAME`: Your Docker Hub username.
      * `DOCKERHUB_TOKEN`: Your Docker Hub Access Token.

### Step 3: Run the Pipeline

The pipeline is fully automated and will be triggered by a push to the `main` branch or by a manual trigger from the GitHub Actions tab.

1.  Make a small change to a file (e.g., `app/main.py`).
2.  Commit and push the change to the `main` branch.
3.  Navigate to the **Actions** tab in your GitHub repository to watch the workflow run.

The workflow will perform the following steps:

1.  **Build & Scan**: Builds the Docker image and runs a Trivy scan for vulnerabilities.
2.  **Provision Infrastructure**: Runs Terraform to create a **Kind** cluster and install **Istio**, **ArgoCD**, and the **Prometheus/Grafana** stack.
3.  **Update Manifests**: Updates the `deployment.yaml` with the new, scanned Docker image tag.
4.  **Git Push**: Commits and pushes the updated manifest file back to the repository, triggering ArgoCD.

### Step 4: Access and Verify

After the workflow completes, you can access your tools to verify the deployment.

1.  **Access ArgoCD**:

      * Port-forward to the ArgoCD server service: `kubectl -n argocd port-forward svc/argocd-server 8080:443`.
      * Get the initial admin password: `kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d`.
      * Open `https://localhost:8080` in your browser. Log in with `admin` and the password. You will see your application automatically synced and healthy.

2.  **Access the Application**:

      * Get the NodePort assigned to your service: `kubectl get svc my-app-service`.
      * Get the IP address of your Kind cluster node: `kubectl get nodes -o wide`.
      * Open a web browser and navigate to `http://<node-ip>:<node-port>` to see your deployed application.

3.  **Monitor with Grafana**:

      * Port-forward to the Grafana service: `kubectl -n monitoring port-forward svc/kube-prometheus-stack-grafana 3000:80`.
      * Open `http://localhost:3000` in your browser. The default credentials are `admin`/`prom-operator`.
      * Explore the pre-built dashboards to monitor your application's metrics.

This project demonstrates a fully automated, secure, and observable GitOps workflow that can be easily adapted for more complex applications and production environments.
