variable "database_password" {
    type = string
}

variable "database_user" {
    type = string
    default = "mailu"
}

variable "mailu_user" {
    type = string
    default = "manager"
}

variable "mailu_password" {
    type = string
}
