.PHONY: up down stop prune ps shell prepare installip platform-build sources db-fetch db-import cc clean

# Read project name from .env file
$(shell cp -n \.env.default \.env)
$(shell cp -n \.\/docker\/docker-compose\.override\.yml\.default \.\/docker\/docker-compose\.override\.yml)
include .env

# Needed variables, to avoid conflicts.
ifeq ($(strip $(PROJECT_NAME)),mysite)
$(error Project name can not be default, please edit ".env" and set PROJECT_NAME variable.)
endif
ifeq ($(strip $(PROJECT_BASE_URL)),mysite.docker.localhost)
$(error Project base URL can not be default, please edit ".env" and set PROJECT_BASE_URL variable.)
endif
ifeq ($(strip $(PLATFORM_PROJECT)),hs50q40ab9yrs)
$(error Platform project can not be default, please edit ".env" and set PLATFORM_PROJECT variable.)
endif
ifeq ($(strip $(PLATFORM_ENVIRONMENT)),site-dev)
$(error Platform environment can not be default, please edit ".env" and set PLATFORM_ENVIRONMENT variable.)
endif

all: up prepare install ip

up:
	@echo "Starting up containers for for $(PROJECT_NAME)..."
	docker-compose pull --parallel
	docker-compose up -d --remove-orphans

down: stop

stop:
	@echo "Stopping containers for $(PROJECT_NAME)..."
	@docker-compose stop

prune:
	@echo "Removing containers for $(PROJECT_NAME)..."
	@docker-compose down -v --remove-orphans

ps:
	@docker ps --filter name='$(PROJECT_NAME)*'

shell:
	docker exec -ti $(shell docker ps --filter name='$(PROJECT_NAME)_php' --format "{{ .ID }}") sh

prepare:
ifneq ("$(wildcard platform)","")
	@echo "Found previous build directory. Skipping build..."
else
	@echo "Fetching project from Platform..."
	@platform get $(PLATFORM_PROJECT) --environment $(PLATFORM_ENVIRONMENT) platform
	@make -s platform-build
endif
	@make -s sources
	@docker exec -ti $(shell docker ps --filter name='$(PROJECT_NAME)_php' --format "{{ .ID }}") sudo chown www-data platform/_www/sites/default/files
	@docker exec -ti $(shell docker ps --filter name='$(PROJECT_NAME)_php' --format "{{ .ID }}") sudo chmod -R 775 platform/_www/sites/default/files

install:
	@make -s db-fetch
	@make -s db-import

ip:
	$(info Container IPs for "$(PROJECT_NAME)":)
	$(eval CONTAINERS := $(shell docker ps -f name=$(PROJECT_NAME) --format "{{ .ID }}"))
	$(foreach CONTAINER, $(CONTAINERS), $(info $(shell docker inspect --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}} : {{.Name}}' $(CONTAINER)) ))

platform-build:
	@echo "Building Platform sources..."
	@cd platform && platform build

sources:
	@echo "Copying custom sources..."
	@cp sources/sites/default/settings.local.php platform/.platform/local/shared/settings.local.php

db-fetch:
	@echo "Fetching database from Platform..."
ifneq ("$(wildcard mariadb-init/$(DB_NAME).sql)","")
	@rm mariadb-init/$(DB_NAME).sql
endif
	@cd platform && platform db:dump -f ../mariadb-init/$(DB_NAME).sql

db-import:
	@echo "Importing database..."
	@docker exec -it $(PROJECT_NAME)_mariadb sh -c "mysql -u $(DB_USER) -p$(DB_PASSWORD) $(DB_NAME) < /docker-entrypoint-initdb.d/$(DB_NAME).sql"
	@make -s cc

cc:
	@echo "Clearing cache..."
	@docker exec -it $(PROJECT_NAME)_php sh -c "cd platform/_www/sites/default && drush cc all"

clean:
ifneq ("$(wildcard platform)","")
	@echo "Cleaning previous build directory..."
	@rm -rf platform
else
	@echo "Nothing to clean..."
endif
