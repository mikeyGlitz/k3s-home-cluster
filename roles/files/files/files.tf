variable "db_password" {
  type        = string
  description = "(optional) describe your variable"
}
variable "db_user" {
  type        = string
  default     = "files_manager"
  description = "(optional) describe your variable"
}

variable "app_user" {
  type        = string
  default     = "manager"
  description = "(optional) describe your variable"
}

variable "app_password" {
  type        = string
  description = ""
}

variable "redis_password" {
  type        = string
  description = ""
}

variable "client_secret" {
  type = string
}

resource "vault_generic_secret" "sec_db_creds" {
  path      = "secret/nextcloud/db/credentials"
  data_json = <<JSON
    {
        "db_user": "${var.db_user}",
        "db_password": "${var.db_password}"
    }
    JSON
}

resource "vault_generic_secret" "sec_app_creds" {
  path      = "secret/nextcloud/app/credentials"
  data_json = <<JSON
    {
        "app_user": "${var.app_user}",
        "app_password": "${var.app_password}"
    }
    JSON
}

resource "helm_release" "rel_files_cloud" {
  repository = "https://nextcloud.github.io/helm/"
  name       = "cloudfiles"
  chart      = "nextcloud"
  namespace  = "files"

  values = [templatefile("${path.module}/values.yaml.tpl", { redisPassword = var.redis_password, client_secret = var.client_secret })]
}
