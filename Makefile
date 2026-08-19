.PHONY: install setup ping

# Установка ролей и коллекций Ansible Galaxy
install:
	ansible-galaxy install -r requirements.yml
	ansible-galaxy collection install -r requirements.yml

# Подготовка серверов: pip, docker
setup:
	ansible-playbook playbook.yml --tags setup -v

ping:
	ansible all -m ping
