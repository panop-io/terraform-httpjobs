# httpjobs agent — Terraform SSH install

Installs and configures the Panop httpjobs agent on remote hosts over SSH.

**Input:** `hosts` in `terraform.tfvars` — one entry per unit with **IP** (`host`), **token**, and **scanner_id**.

**Fixed in code:** Tower `https://tower.panop.dev`, engine `docker`, SSH `debian@host:22` using your local **ssh-agent** (no password in Terraform).

Each `terraform apply` re-runs the remote install (see `always_run` in `main.tf`).

## Install Terraform

This repo needs **Terraform ≥ 1.5.0** (see `versions.tf`).

### macOS (Homebrew)

```bash
brew tap hashicorp/tap
brew install hashicorp/tap/terraform
terraform version
```

### Linux (Debian / Ubuntu)

```bash
sudo apt-get update && sudo apt-get install -y gnupg software-properties-common
wget -O- https://apt.releases.hashicorp.com/gpg | \
  sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
  https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
  sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt-get update && sudo apt-get install -y terraform
terraform version
```

Other platforms: [Install Terraform](https://developer.hashicorp.com/terraform/install).

## Deploy procedure

1. **SSH access** — Your key must work as `debian` on each host:

   ```bash
   eval "$(ssh-agent -s)"
   ssh-add ~/.ssh/id_ed25519   # or your key
   ssh debian@YOUR_HOST
   ```

2. **Configure hosts** — Copy the example file; real values stay local (see `.gitignore`).

   ```bash
   cd ~/dev/terraform-httpjobs
   cp terraform.tfvars.example terraform.tfvars
   # edit hosts: host (IP), token, scanner_id
   ```

3. **Init and apply**

   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

4. **Verify on the server** (optional)

   ```bash
   ssh debian@YOUR_HOST 'systemctl is-active panop-svc-httpjobs'
   ```

## Files

| File | Purpose |
|------|---------|
| `terraform.tfvars` | Your hosts, tokens, scanner IDs (local, not in git) |
| `terraform.tfvars.example` | Template |
| `variables.tf` | Variable definition for `hosts` |
| `main.tf` | SSH install script |
| `locals.tf` | Tower URL, download URL, engine |
