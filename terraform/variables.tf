variable "cloud_id" {
  type    = string
  default = "b1gtgnuahgejckvs46i5"
}

variable "folder_id" {
  type    = string
  default = "b1glbnnomnf50r9g8kef"
}

variable "zone" {
  type    = string
  default = "ru-central1-a"
}

variable "network_id" {
  type    = string
  default = "enp3arvrk14mj2rkbfac"
}

variable "subnet_id" {
  type    = string
  default = "e9be2tegggqb0962hbv4" # default-ru-central1-a
}

variable "vm_image_family" {
  type    = string
  default = "ubuntu-2204-lts"
}

variable "ssh_user" {
  type    = string
  default = "ubuntu"
}

variable "ssh_public_key_path" {
  type    = string
  default = "~/.ssh/ssh-key-yandex-cloud.pub"
}

variable "redmine_port" {
  type    = number
  default = 3000
}

variable "db_name" {
  type    = string
  default = "redmine"
}

variable "db_user" {
  type    = string
  default = "redmine"
}

variable "db_password" {
  type      = string
  sensitive = true
}

variable "acme_challenge_path" {
  type    = string
  default = ""
}

variable "acme_challenge_content" {
  type    = string
  default = ""
}

variable "balancer_ip" {
  type    = string
  default = "51.250.37.125"
}
