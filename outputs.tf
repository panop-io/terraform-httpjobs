output "units" {
  description = "Logical name => host + scanner id (tokens omitted)"
  value = {
    for name, h in var.hosts : name => {
      host       = h.host
      scanner_id = h.scanner_id
    }
  }
}

output "unit_count" {
  value = length(var.hosts)
}
