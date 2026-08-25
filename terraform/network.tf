# Группа безопасности для виртуальных машин:
# 22 (ssh) и порт приложения только от балансировщика/health-check.
resource "yandex_vpc_security_group" "webservers" {
  name       = "redmine-webservers-sg"
  network_id = var.network_id

  ingress {
    protocol       = "TCP"
    description    = "SSH"
    port           = 22
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol          = "TCP"
    description       = "App port from load balancer"
    port              = var.redmine_port
    security_group_id = yandex_vpc_security_group.balancer.id
  }

  ingress {
    protocol       = "TCP"
    description    = "App port health checks from Yandex ALB ranges"
    port           = var.redmine_port
    v4_cidr_blocks = ["198.18.235.0/24", "198.18.248.0/24"]
  }

  ingress {
    protocol          = "ANY"
    description       = "Internal traffic within the security group"
    predefined_target = "self_security_group"
  }

  egress {
    protocol       = "ANY"
    description    = "All outbound"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

# Группа безопасности балансировщика:
# 80/443 для приложения, 30080 для health-check балансера.
resource "yandex_vpc_security_group" "balancer" {
  name       = "redmine-balancer-sg"
  network_id = var.network_id

  ingress {
    protocol       = "TCP"
    description    = "HTTP"
    port           = 80
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol       = "TCP"
    description    = "HTTPS"
    port           = 443
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol       = "TCP"
    description    = "Load balancer health checks"
    port           = 30080
    v4_cidr_blocks = ["198.18.235.0/24", "198.18.248.0/24"]
  }

  egress {
    protocol       = "ANY"
    description    = "All outbound"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}
