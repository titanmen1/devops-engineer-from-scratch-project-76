### Hexlet tests and linter status:
[![Actions Status](https://github.com/titanmen1/devops-engineer-from-scratch-project-76/actions/workflows/hexlet-check.yml/badge.svg)](https://github.com/titanmen1/devops-engineer-from-scratch-project-76/actions)

# DevOps Deploy Project

Развёртывание приложения [Redmine](https://www.redmine.org/) на инфраструктуре
Yandex Cloud с помощью Ansible: две виртуальные машины за L7-балансировщиком
(Application Load Balancer), внешний кластер Managed PostgreSQL и мониторинг DataDog.

## Требования

* UNIX-система
* Make
* Ansible 2.15+
* Доступ по SSH к серверам (ключ `~/.ssh/ssh-key-yandex-cloud`)

## Инфраструктура

Инфраструктура (2 ВМ, VPC security groups, ALB, кластер Managed PostgreSQL)
описана в Terraform (каталог `terraform/`, в репозиторий не коммитится).
Создаётся командами:

```bash
cd terraform
export YC_TOKEN=$(yc iam create-token)
terraform init
terraform apply
```

После применения внешние IP серверов и балансировщика, а также FQDN хоста БД
доступны через `terraform output`.

## Подготовка

1. Установите роли и коллекции Ansible Galaxy:

   ```bash
   make install
   ```

2. Пропишите в `inventory.ini` внешние IP-адреса серверов (из `terraform output`).

3. Создайте файл с паролем от Ansible Vault:

   ```bash
   echo "ваш_пароль" > vault-password
   ```

4. Заполните секреты (параметры БД и ключ DataDog) в зашифрованном хранилище:

   ```bash
   make edit-vault
   ```

   В файле должны быть переменные:

   ```yaml
   vault_db_host: <FQDN хоста PostgreSQL>
   vault_db_port: 6432
   vault_db_name: redmine
   vault_db_username: redmine
   vault_db_password: <пароль от БД>
   vault_db_sslmode: require
   vault_datadog_api_key: <API-ключ DataDog>
   ```

## Развёртывание

Подготовка серверов (устанавливает pip и Docker, настройки серверов):

```bash
make setup
```

Деплой приложения (запускает только контейнер Redmine, без изменения настроек серверов):

```bash
make deploy
```

Полный прогон (подготовка + деплой + мониторинг):

```bash
make all
```

> Для мониторинга (`make all`) требуется реальный `vault_datadog_api_key` в
> зашифрованном хранилище. Без него используйте `make setup` и `make deploy`.
> Мониторинг DataDog запускается только для группы хостов `webservers`.

## Проверка

Приложение доступно по внешнему IP балансировщика на 80 порту, а также по
внешнему IP любого из серверов на порту `redmine_port` (по умолчанию 3000).

## Команды Makefile

| Команда              | Назначение                                          |
| -------------------- | --------------------------------------------------- |
| `make install`       | Установка ролей и коллекций Ansible Galaxy           |
| `make setup`         | Подготовка серверов (pip, Docker)                    |
| `make deploy`        | Деплой приложения Redmine                            |
| `make all`           | Полный прогон плейбука                                |
| `make ping`          | Проверка доступности серверов                         |
| `make edit-vault`    | Редактирование зашифрованных секретов                 |
| `make view-vault`    | Просмотр зашифрованных секретов                       |
| `make encrypt-vault` | Зашифровать файл с секретами                          |
| `make decrypt-vault` | Расшифровать файл с секретами                         |

## Ссылка на задеплоенное приложение

Приложение развёрнуто и доступно по внешнему IP балансировщика:
**http://51.250.37.125/**

_Домен пока не зарегистрирован; после регистрации приложение будет доступно
по доменному имени, а балансировщик — терминировать TLS для https._
