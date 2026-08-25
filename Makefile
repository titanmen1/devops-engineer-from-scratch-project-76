.PHONY: install setup deploy all ping edit-vault view-vault encrypt-vault decrypt-vault

# Установка ролей и коллекций Ansible Galaxy
install:
	ansible-galaxy install -r requirements.yml

# Подготовка серверов: pip, docker (без деплоя приложения)
setup:
	ansible-playbook playbook.yml --tags setup --vault-password-file vault-password -v

# Деплой приложения Redmine (без изменения настроек серверов)
deploy:
	ansible-playbook playbook.yml --tags deploy --vault-password-file vault-password -v

# Полный прогон: подготовка + деплой + мониторинг
all:
	ansible-playbook playbook.yml --vault-password-file vault-password -v

ping:
	ansible all -m ping --vault-password-file vault-password

edit-vault:
	ansible-vault edit group_vars/webservers/vault.yml --vault-password-file vault-password

view-vault:
	ansible-vault view group_vars/webservers/vault.yml --vault-password-file vault-password

encrypt-vault:
	ansible-vault encrypt group_vars/webservers/vault.yml --vault-password-file vault-password

decrypt-vault:
	ansible-vault decrypt group_vars/webservers/vault.yml --vault-password-file vault-password
