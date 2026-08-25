output "web_external_ips" {
  description = "Внешние IP веб-серверов"
  value       = [for vm in yandex_compute_instance.web : vm.network_interface.0.nat_ip_address]
}

output "web_internal_ips" {
  description = "Внутренние IP веб-серверов"
  value       = [for vm in yandex_compute_instance.web : vm.network_interface.0.ip_address]
}

output "load_balancer_ip" {
  description = "Внешний IP балансировщика"
  value = try(
    yandex_alb_load_balancer.redmine.listener[0].endpoint[0].address[0].external_ipv4_address[0].address,
    null
  )
}

output "db_host" {
  description = "FQDN хоста БД"
  value       = yandex_mdb_postgresql_cluster.redmine.host[0].fqdn
}

output "db_name" {
  value = yandex_mdb_postgresql_database.redmine.name
}

output "db_user" {
  value = yandex_mdb_postgresql_user.redmine.name
}
