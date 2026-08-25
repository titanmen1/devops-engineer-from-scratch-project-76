# Целевая группа: две ВМ с приложением
resource "yandex_alb_target_group" "redmine" {
  name = "redmine-target-group"

  dynamic "target" {
    for_each = yandex_compute_instance.web
    content {
      subnet_id  = var.subnet_id
      ip_address = target.value.network_interface.0.ip_address
    }
  }
}

# Группа бэкендов с проверкой состояния (health check на порт 30080)
resource "yandex_alb_backend_group" "redmine" {
  name = "redmine-backend-group"

  http_backend {
    name             = "redmine-http-backend"
    weight           = 1
    port             = var.redmine_port
    target_group_ids = [yandex_alb_target_group.redmine.id]

    load_balancing_config {
      panic_threshold = 90
    }

    healthcheck {
      timeout             = "10s"
      interval            = "2s"
      healthy_threshold   = 2
      unhealthy_threshold = 5
      http_healthcheck {
        path = "/"
      }
    }
  }
}

# HTTP-роутер: перенаправляет все запросы в группу бэкендов
resource "yandex_alb_http_router" "redmine" {
  name = "redmine-http-router"
}

resource "yandex_alb_virtual_host" "redmine" {
  name           = "redmine-virtual-host"
  http_router_id = yandex_alb_http_router.redmine.id

  # ACME HTTP-challenge для валидации TLS-сертификата.
  # Отдаёт содержимое challenge по пути /.well-known/acme-challenge/<token>.
  # Оставить пустым (acme_challenge_path = "") после выпуска сертификата.
  dynamic "route" {
    for_each = var.acme_challenge_path == "" ? [] : [1]
    content {
      name = "acme-challenge"
      http_route {
        http_match {
          path {
            exact = var.acme_challenge_path
          }
        }
        direct_response_action {
          status = 200
          body   = var.acme_challenge_content
        }
      }
    }
  }

  route {
    name = "root"
    http_route {
      http_route_action {
        backend_group_id = yandex_alb_backend_group.redmine.id
        timeout          = "60s"
      }
    }
  }
}

# Сам балансировщик L7 со слушателем на 80 порту
resource "yandex_alb_load_balancer" "redmine" {
  name               = "redmine-load-balancer"
  network_id         = var.network_id
  security_group_ids = [yandex_vpc_security_group.balancer.id]

  allocation_policy {
    location {
      zone_id   = var.zone
      subnet_id = var.subnet_id
    }
  }

  listener {
    name = "http-listener"
    endpoint {
      address {
        external_ipv4_address {
          address = var.balancer_ip
        }
      }
      ports = [80]
    }
    http {
      handler {
        http_router_id = yandex_alb_http_router.redmine.id
      }
    }
  }

  listener {
    name = "https-listener"
    endpoint {
      address {
        external_ipv4_address {
          address = var.balancer_ip
        }
      }
      ports = [443]
    }
    tls {
      default_handler {
        http_handler {
          http_router_id = yandex_alb_http_router.redmine.id
        }
        certificate_ids = [yandex_cm_certificate.redmine.id]
      }
    }
  }
}
