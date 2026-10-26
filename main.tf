resource "null_resource" "httpjobs_agent" {
  for_each = var.hosts

  triggers = {
    host                = each.value.host
    scanner_id          = each.value.scanner_id
    token_hash          = sha256(each.value.token)
    install_fingerprint = local.install_fingerprint
    unit_key            = each.key
    # Forces replace on every apply so remote-exec always runs.
    always_run          = timestamp()
  }

  connection {
    type        = "ssh"
    user        = "debian"
    host        = each.value.host
    port        = 22
    agent       = true
    timeout     = "5m"
  }

  provisioner "remote-exec" {
    inline = [
      "set -euo pipefail",
      "export DEBIAN_FRONTEND=noninteractive",
      "if ! command -v curl >/dev/null 2>&1; then (command -v apt-get >/dev/null && apt-get update -y && apt-get install -y curl ca-certificates) || yum install -y curl ca-certificates; fi",
      "TMP=$(mktemp -d)",
      "trap 'rm -rf \"$TMP\"' EXIT",
      "cd \"$TMP\"",
      "curl -fsSL -H 'Authorization: Bearer ${each.value.token}' '${local.download_url}' -o panop-svc-httpjobs.tar.gz",
      "tar -xzf panop-svc-httpjobs.tar.gz",
      "sudo install -m 755 panop-svc-httpjobs /usr/local/bin/panop-svc-httpjobs",
      "sudo panop-svc-httpjobs install --token '${each.value.token}' --scanner-id '${each.value.scanner_id}' --tower-url '${local.tower_url}' --engine ${local.engine}",
      "systemctl is-active --quiet panop-svc-httpjobs || systemctl status panop-svc-httpjobs --no-pager || true",
    ]
  }
}
