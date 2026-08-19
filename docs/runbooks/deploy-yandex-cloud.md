# Runbook: развёртывание Redmine в Yandex Cloud

## Цель

С нуля поднять инфраструктуру в Yandex Cloud (2 ВМ + ALB + Managed PostgreSQL)
и задеплоить Redmine через Ansible. Инфраструктура описана в Terraform
(каталог `terraform/`, **в git не коммитится** по договорённости).

## Предусловия

- Установлены `yc`, `terraform`, `ansible`
- `yc` авторизован (service account key), folder-id `b1glbnnomnf50r9g8kef`
- SSH-пара `~/.ssh/ssh-key-yandex-cloud` (+ `.pub`)
- Каталог `terraform/` с конфигами (providers, variables, network, compute,
  alb, database, outputs) — восстанавливается из этого runbook при утере

## Шаги

### 1. Инфраструктура через Terraform

```bash
cd terraform
# пароль БД (>=8 символов, латиница+цифры)
printf 'db_password = "<СГЕНЕРИРОВАННЫЙ_ПАРОЛЬ>"\n' > terraform.tfvars

export YC_TOKEN=$(yc iam create-token)   # токен живёт ~12ч
terraform init
terraform apply                          # ~5-10 мин (дольше всего создаётся PG)

terraform output    # web_external_ips, load_balancer_ip, db_host
```

### 2. Инвентарь и секреты Ansible

```bash
cd ..
# внешние IP серверов из terraform output -> inventory.ini (web1/web2)
# пароль vault:
printf '<VAULT_PASSWORD>\n' > vault-password

# vault со значениями БД (db_host из terraform output, пароль из terraform.tfvars):
make edit-vault    # заполнить vault_db_* и vault_datadog_api_key
```

### 3. Роли, подготовка серверов, деплой

```bash
make install       # роли и коллекции Ansible Galaxy
make ping          # проверка SSH до web1/web2
make setup         # pip + docker (тег setup)
make deploy        # контейнер Redmine (тег deploy)
```

### 4. Открыть порт приложения для балансировщика

По умолчанию SG `webservers` пускает порт приложения (3000) только от SG
балансировщика и служебных диапазонов health-check ALB
(`198.18.235.0/24`, `198.18.248.0/24`). Это уже описано в `terraform/network.tf`.

## Проверка

```bash
# на сервере приложение слушает 3000 (проверять с самого сервера — снаружи закрыто):
ssh -i ~/.ssh/ssh-key-yandex-cloud ubuntu@<WEB1_IP> \
  'curl -s -o /dev/null -w "%{http_code}\n" http://localhost:3000/'   # -> 200

# через балансировщик снаружи:
curl -s -o /dev/null -w "%{http_code}\n" http://<LB_IP>/               # -> 200
curl -s http://<LB_IP>/ | grep -o '<title>[^<]*</title>'              # -> <title>Redmine</title>
```

Ожидаемо: Redmine стартует не мгновенно — на первом запуске идут миграции БД.
В логах `sudo docker logs redmine-app` должно появиться `Listening on http://0.0.0.0:3000`.

## Грабли

- **Битый NAT-IP на ВМ (главная потеря времени).** Свежесозданной ВМ Yandex
  может выдать внешний IP, у которого работает исходящий NAT
  (`curl ifconfig.me` с ВМ отвечает), но **не работают входящие соединения**:
  снаружи `ssh`/`curl` виснет с `kex_exchange_identification: Connection closed`,
  при этом изнутри VPC sshd на этой же ВМ отдаёт баннер нормально. Пересоздание
  ВМ не помогло — новый инстанс получил такой же дефект. Помогла **смена NAT-IP**:
  ```bash
  yc compute instance remove-one-to-one-nat --id <VM_ID> --network-interface-index 0
  yc compute instance add-one-to-one-nat    --id <VM_ID> --network-interface-index 0
  # затем обновить внешний IP в inventory.ini и synchronize terraform state
  ```
  Диагностика, отличающая этот случай: `python3 -c "import socket;
  print(socket.create_connection(('<IP>',22),5).recv(60))"` — timeout снаружи,
  но баннер `SSH-2.0-...` при том же тесте с соседней ВМ по внутреннему IP.

- **Не долбить sshd циклом ожидания.** Параллельные `until ssh ...; sleep` создают
  полуоткрытые соединения и маскируют картину (похоже на бан). Ждать доступности
  ВМ одним циклом, не запускать несколько ожиданий одновременно.

- **HTTP 000 напрямую на порт 3000 — это норма.** SG закрывает порт приложения
  для всех, кроме балансировщика. Проверять приложение снаружи только через LB,
  а на самой ВМ — через `localhost:3000`.

- **Балансировщик коннектится, но не отвечает** = бэкенды unhealthy. Причина была
  в SG: порт приложения не был открыт от SG балансировщика. Исправлено правилом
  `security_group_id = balancer.id` на порт `redmine_port` в SG `webservers`.

- **`terraform apply -auto-approve`** блокируется авто-классификатором ассистента
  (создаёт платные ресурсы) — запускать под контролем человека.

- **YC_TOKEN истекает** (~12ч). Перед каждой сессией terraform: `export YC_TOKEN=$(yc iam create-token)`.

## Откат

```bash
cd terraform
export YC_TOKEN=$(yc iam create-token)
terraform destroy      # удаляет ВМ, ALB, SG, кластер PostgreSQL
```
