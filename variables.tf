# Values for `hosts`, `panop_token`, `agent_mode`, and optional `ssh_user` go in terraform.tfvars.

variable "ssh_user" {
  description = "SSH login for all hosts (ssh-agent auth; same user on every unit)"
  type        = string
  default     = "debian"
}

variable "agent_mode" {
  description = "install: deploy agent via systemd and remove panop-svc-httpjobs docker containers (no error if none). uninstall: remove systemd unit only (no docker changes)"
  type        = string
  default     = "install"

  validation {
    condition     = contains(["install", "uninstall"], var.agent_mode)
    error_message = "agent_mode must be \"install\" or \"uninstall\"."
  }
}

variable "force_reapply_on_every_apply" {
  description = "If true, remote script runs on every terraform apply (re-install or re-uninstall). If false, only when mode, hosts, token, or install fingerprint change"
  type        = bool
  default     = false
}

variable "panop_token" {
  description = "Panop API token used to download panop-svc-httpjobs (install and uninstall)"
  type        = string
  sensitive   = true
}

variable "hosts" {
  description = "Map of unit name => { host (public IP), scanner_id (UUID) }"
  type = map(object({
    host       = string
    scanner_id = string
  }))

  validation {
    condition     = length(var.hosts) > 0
    error_message = "hosts must contain at least one entry."
  }
}
