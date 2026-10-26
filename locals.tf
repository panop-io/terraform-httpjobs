locals {
  tower_url    = "https://tower.panop.dev"
  engine       = "docker"
  download_url = "${local.tower_url}/api/scanner/httpjobs/download/linux-amd64.tar.gz"

  install_fingerprint = sha256(join("|", [
    local.download_url,
    local.tower_url,
    local.engine,
  ]))
}
