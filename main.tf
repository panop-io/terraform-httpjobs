resource "null_resource" "httpjobs_agent" {
  for_each = var.hosts

  triggers = {
    agent_mode          = var.agent_mode
    host                = each.value.host
    scanner_id          = each.value.scanner_id
    token_hash          = sha256(var.panop_token)
    install_fingerprint = local.install_fingerprint
    unit_key            = each.key
    force_reapply       = var.force_reapply_on_every_apply ? timestamp() : "static"
  }

  connection {
    type    = "ssh"
    user    = var.ssh_user
    host    = each.value.host
    port    = 22
    agent   = true
    timeout = "5m"
  }

  provisioner "remote-exec" {
    inline = var.agent_mode == "install" ? concat(
      local.remote_prepare_install,
      [
        "echo 'httpjobs: install ${each.key} on ${each.value.host}'",
      ],
      local.remote_docker_remove_httpjobs_optional,
      [
        "sudo panop-svc-httpjobs install --token '${var.panop_token}' --scanner-id '${each.value.scanner_id}' --tower-url '${local.tower_url}' --engine ${local.engine}",
        "systemctl is-active --quiet ${local.httpjobs_systemd_unit} || { systemctl status ${local.httpjobs_systemd_unit} --no-pager || true; echo 'httpjobs: ${local.httpjobs_systemd_unit} is not active'; exit 1; }",
      ],
      local.remote_docker_remove_httpjobs_optional,
      [
        "echo 'httpjobs: install complete (${local.httpjobs_systemd_unit} active, docker httpjobs containers cleared)'",
      ],
    ) : concat(
      local.remote_prepare_uninstall,
      [
        "echo 'httpjobs: uninstall systemd ${each.key} on ${each.value.host}'",
        "UNIT='${local.httpjobs_systemd_unit}'",
        "systemd_installed=0",
        "if systemctl cat \"$UNIT.service\" >/dev/null 2>&1 || sudo systemctl cat \"$UNIT.service\" >/dev/null 2>&1; then systemd_installed=1; fi",
        "if [ \"$systemd_installed\" = 0 ] && [ -f \"/etc/systemd/system/$UNIT.service\" ]; then systemd_installed=1; fi",
        "if [ \"$systemd_installed\" = 0 ] && [ -f \"/lib/systemd/system/$UNIT.service\" ]; then systemd_installed=1; fi",
        "if [ \"$systemd_installed\" = 0 ] && [ -f \"/usr/lib/systemd/system/$UNIT.service\" ]; then systemd_installed=1; fi",
        "if [ \"$systemd_installed\" = 0 ]; then echo \"skip: $UNIT not installed\"; exit 0; fi",
        "sudo systemctl stop \"$UNIT\" 2>/dev/null || true",
        "sudo systemctl disable \"$UNIT\" 2>/dev/null || true",
        "if [ -x /usr/local/bin/panop-svc-httpjobs ]; then sudo panop-svc-httpjobs uninstall; else echo 'httpjobs: binary already removed'; fi",
        "sudo rm -f /etc/systemd/system/$UNIT.service /lib/systemd/system/$UNIT.service /usr/lib/systemd/system/$UNIT.service",
        "sudo systemctl daemon-reload 2>/dev/null || true",
        "echo 'httpjobs: systemd uninstall complete'",
      ],
    )
  }
}
