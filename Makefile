.PHONY: install setup deploy ping

# Установка ролей и коллекций Ansible Galaxy
install:
	ansible-galaxy install -r requirements.yml
	ansible-galaxy collection install -r requirements.yml

# Подготовка серверов: pip, docker (без деплоя приложения)
setup:
	ansible-playbook playbook.yml --tags setup -v

# Деплой приложения Redmine (без изменения настроек серверов)
deploy:
	ansible-playbook playbook.yml --tags deploy -v

ping:
	ansible all -m ping
