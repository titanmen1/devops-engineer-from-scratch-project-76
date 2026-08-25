# Группа безопасности для кластера БД: доступ на 6432 только из SG веб-серверов
resource "yandex_vpc_security_group" "postgresql" {
  name       = "redmine-postgresql-sg"
  network_id = var.network_id

  ingress {
    protocol          = "TCP"
    description       = "PostgreSQL access from webservers only"
    port              = 6432
    security_group_id = yandex_vpc_security_group.webservers.id
  }

  egress {
    protocol       = "ANY"
    description    = "All outbound"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "yandex_mdb_postgresql_cluster" "redmine" {
  name        = "redmine-pg"
  environment = "PRESTABLE"
  network_id  = var.network_id

  security_group_ids = [yandex_vpc_security_group.postgresql.id]

  config {
    version = "16"
    resources {
      resource_preset_id = "s2.micro"
      disk_type_id       = "network-ssd"
      disk_size          = 20
    }
  }

  host {
    zone      = var.zone
    subnet_id = var.subnet_id
  }
}

resource "yandex_mdb_postgresql_database" "redmine" {
  cluster_id = yandex_mdb_postgresql_cluster.redmine.id
  name       = var.db_name
  owner      = yandex_mdb_postgresql_user.redmine.name
}

resource "yandex_mdb_postgresql_user" "redmine" {
  cluster_id = yandex_mdb_postgresql_cluster.redmine.id
  name       = var.db_user
  password   = var.db_password
}
