# httpjobs agent — Terraform SSH install

Installs or uninstalls the Panop httpjobs agent on remote hosts over SSH.

**Input (in `terraform.tfvars`):**

- `ssh_user` — SSH login for every host (default `debian`)
- `agent_mode` — `install` (default) or `uninstall`
- `panop_token` — Panop API token (install only; used to download the CLI)
- `hosts` — map of name → **public IP** (`host`) and **scanner UUID** (`scanner_id`)

**Fixed in code:** Tower `https://tower.panop.dev`, engine `docker`, SSH `user@host:22` via **ssh-agent** (no password in Terraform).

**Install** — removes **panop-svc-httpjobs** Docker containers if present (no error if none), runs `panop-svc-httpjobs install`, requires **`panop-svc-httpjobs.service` active**, then removes those Docker containers again.

**Uninstall** — **systemd only** (no Docker): stop/disable unit, `panop-svc-httpjobs uninstall`, delete unit file; skips quietly if unit missing.

By default, `terraform apply` is **idempotent** (no SSH) until `agent_mode`, `hosts`, token, or Tower settings change. Set `force_reapply_on_every_apply = true` to re-run install/uninstall on every apply.

| `agent_mode` | Effect |
|--------------|--------|
| `install` | Systemd agent active; **panop-svc-httpjobs** Docker containers removed (optional cleanup, never fails if absent). |
| `uninstall` | Systemd unit removed only; **Docker untouched** (e.g. akamai-toolbox stays). |

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

1. **SSH access** — Your key must work as `ssh_user` (e.g. `debian`) on each host:

   ```bash
   eval "$(ssh-agent -s)"
   ssh-add ~/.ssh/id_ed25519   # or your key
   ssh debian@YOUR_HOST        # match ssh_user in tfvars
   ```

2. **Configure hosts** — Copy the example file; real values stay local (see `.gitignore`).

   ```bash
   cd ~/dev/terraform-httpjobs
   cp terraform.tfvars.example terraform.tfvars
   # edit ssh_user, agent_mode, panop_token, hosts (IP + scanner_id)
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
