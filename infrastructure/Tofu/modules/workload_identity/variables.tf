variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "oidc_provider_arn" {
  type = string
}

variable "oidc_issuer_url" {
  type = string
}

variable "service_accounts" {
  type = map(object({
    namespace       = string
    service_account = string
    policy_json     = string
  }))
}
