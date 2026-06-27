# GKE Terraform Deployment

Short: Terraform-based provisioning of a secure GKE cluster on Google Cloud.

## What this repo provisions
- Custom VPC (`gke-vpc`) and subnet (`gke-subnet`, 10.0.0.0/20).
- GKE cluster with private nodes (no external node IPs) and a public control plane.
  - Master authorized networks (restricts control plane access to configured CIDR).
  - Workload Identity enabled for secure pod-to-GCP access.
  - Separate managed node pool with autoscaling and lifecycle settings.
  - IP allocation policy using secondary ranges for Pods and Services.
- Network components: Cloud Router and Cloud NAT for outbound internet access from private nodes.
- Firewall rules for GKE master access and Google Load Balancer health checks.
- Terraform remote state stored in Google Cloud Storage (GCS) backend.

## Architecture (summary)
1. Terraform defines networking, GKE cluster, node pools, and supporting resources.
2. VPC/subnet hosts private nodes. Cloud Router + Cloud NAT provide secure outbound traffic.
3. Control plane is public but access is limited via master-authorized CIDRs.
4. Workload Identity maps Kubernetes ServiceAccounts to GCP ServiceAccounts (no key files).
5. Terraform state is centralized in GCS to enable team collaboration and CI pipelines.

## Security highlights
- Private nodes (no external IPs) reduce attack surface.
- Master authorized networks to restrict API server access.
- Workload Identity avoids static GCP service account keys in pods.
- Firewall rules limit ingress to only required ranges and ports.
- Auto-upgrade and auto-repair reduce time-to-patch for node vulnerabilities.

## How to provision (quick)
Prerequisites:
- Terraform installed (v1.x preferred)
- gcloud CLI installed and authenticated
- Google project and billing enabled
- Replace placeholder values (e.g., `YOUR_HOME_IP/32`) in `gke.tf` before apply

Init, plan, apply:

```bash
cd terraform-gke
terraform init
terraform plan -out plan.tfplan
terraform apply plan.tfplan
```

Notes:
- Terraform backend is configured to use a GCS bucket (see `main.tf`). Ensure your account has access to that bucket.
- After cluster creation, update the `gke-master-access` firewall `source_ranges` with the actual control-plane CIDR if needed.

## Next steps / improvements
- Lock down GCS backend with strict IAM and enable bucket versioning/CMEK.
- Consider enabling a private control plane or restricting admin access via VPN/bastion.
- Add CI checks (tfsec/checkov) and policy enforcement (OPA/Sentinel).

## Files of interest
- `gke.tf` - GKE cluster and node pool
- `network.tf` - VPC, subnet, NAT, router, and firewall rules
- `main.tf` - Terraform backend and provider configuration

---
Generated summary for documentation and quick onboarding.