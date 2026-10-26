# Values for `hosts` go in terraform.tfvars (see terraform.tfvars.example).
variable "hosts" {
  description = "Map of unit name => { host (IP), token, scanner_id }"
  type = map(object({
    host       = string
    token      = string
    scanner_id = string
  }))

  validation {
    condition     = length(var.hosts) > 0
    error_message = "hosts must contain at least one entry."
  }
}
