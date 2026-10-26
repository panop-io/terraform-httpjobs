locals {
  tower_url    = "https://tower.panop.dev"
  engine       = "docker"
  download_url = "${local.tower_url}/api/scanner/httpjobs/download/linux-amd64.tar.gz"

  httpjobs_systemd_unit    = "panop-svc-httpjobs"
  httpjobs_container_image = "exo.container-registry.com/panop/panop-svc-httpjobs:latest"
  httpjobs_image_match     = "panop-svc-httpjobs"

  install_fingerprint = sha256(join("|", [
    local.download_url,
    local.tower_url,
    local.engine,
  ]))

  remote_prepare_install = [
    "set -eu",
    "export DEBIAN_FRONTEND=noninteractive",
    "if ! command -v curl >/dev/null 2>&1; then (command -v apt-get >/dev/null && apt-get update -y && apt-get install -y curl ca-certificates) || yum install -y curl ca-certificates; fi",
    "TMP=$(mktemp -d)",
    "trap 'rm -rf \"$TMP\"' EXIT",
    "cd \"$TMP\"",
    "curl -fsSL -H 'Authorization: Bearer ${var.panop_token}' '${local.download_url}' -o panop-svc-httpjobs.tar.gz",
    "tar -xzf panop-svc-httpjobs.tar.gz",
    "sudo install -m 755 panop-svc-httpjobs /usr/local/bin/panop-svc-httpjobs",
  ]

  # Install only: remove panop httpjobs containers if any; no-op when none (never fails apply).
  remote_docker_remove_httpjobs_optional = [
    "if command -v docker >/dev/null 2>&1; then",
    "  if sudo docker info >/dev/null 2>&1; then DOCKER='sudo docker'; elif docker info >/dev/null 2>&1; then DOCKER=docker; else DOCKER=''; fi",
    "  if [ -n \"$DOCKER\" ]; then",
    "    ids=$($DOCKER ps -a --format '{{.ID}} {{.Image}}' | awk '/${local.httpjobs_image_match}/ {print $1}' || true)",
    "    if [ -n \"$ids\" ]; then echo 'httpjobs: removing docker container(s) for ${local.httpjobs_image_match}'; $DOCKER rm -f $ids || true; else echo 'httpjobs: no docker container for ${local.httpjobs_image_match}'; fi",
    "  fi",
    "fi",
  ]

  remote_prepare_uninstall = [
    "set -eu",
  ]
}
