variable "domain" {
  type    = string
  default = "hexlet-third-project.crabdance.com"
}

# Managed-сертификат Let's Encrypt с DNS-валидацией.
# После создания нужно добавить CNAME-запись (challenge) у регистратора домена.
resource "yandex_cm_certificate" "redmine" {
  name    = "redmine-cert"
  domains = [var.domain]

  managed {
    challenge_type = "HTTP"
  }
}

output "cert_challenge" {
  description = "CNAME challenge для DNS-валидации сертификата"
  value       = yandex_cm_certificate.redmine.challenges
}

output "cert_id" {
  value = yandex_cm_certificate.redmine.id
}
