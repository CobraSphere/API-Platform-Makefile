.ONESHELL:
SHELL := /bin/bash

## Previously used for manual deployments outside of Bitbucket Pipelines
BITBUCKET_COMMIT := $(shell git log -1 --pretty=format:'%h')
BITBUCKET_TAG_SEMVER := $(shell git tag --contains $(BITBUCKET_COMMIT))

###

no-commands:
	@echo "No commands options were specified"

dev-env-permissions: ## this is not slick, but we want to avoid creating tmp in IBM CF, so have chosen not to commit a ./tmp folder
	@mkdir -p ./api/tmp && chmod 777 ./api/tmp

stack-up:
	docker-compose up -d

composer-install:
	docker-compose exec php composer install

run-migrations:
	docker-compose exec php php bin/console doctrine:migrations:migrate --no-interaction

up: dev-env-permissions stack-up run-migrations

logs:
	docker-compose logs -f

show-migrations:
	docker-compose exec php php bin/console doctrine:migrations:status --show-versions

cache-clear:
	docker-compose exec php php bin/console cache:clear

install-assets:
	docker-compose exec php php bin/console assets:install

force-drop-db:
	docker-compose exec php php bin/console doctrine:database:drop --force

create-db:
	docker-compose exec php php bin/console doctrine:database:create

create-schema:
	docker-compose exec php php bin/console doctrine:schema:create

recreate-db: up force-drop-db create-db create-schema cache-clear

connect-db:
	docker-compose exec database psql -U api-platform api

## Use this when you want to use UUID instead of integer based ids for entities
pg-uuid-setup:
	docker-compose exec database psql -U api-platform api -c "CREATE EXTENSION IF NOT EXISTS \"uuid-ossp\";"

append-services-fixtures: up
	docker-compose exec php php bin/console doctrine:fixtures:load --append --group=services

entity:
	docker-compose exec php php bin/console make:entity

controller:
	docker-compose exec php php bin/console make:controller

form:
	docker-compose exec php php bin/console make:form

migration: cache-clear
	docker-compose exec php php bin/console make:migration

build:
	docker-compose -f docker-compose.yaml build

install-and-reset-db: up composer-install run-migrations cache-clear 

install-upgrade: up composer-install run-migrations cache-clear 

install-first-time: install-and-reset-db

install:
	$(info  )
	$(info ***************************************************************************************)
	$(info *** Please use `make install-and-reset-db` or `make install-upgrade` as appropriate ***)
	$(info ***************************************************************************************)
	$(info  )

show-routes:
	docker-compose exec php php bin/console debug:router

pg-dump:
	docker-compose exec database pg_dump -U api > ./_backups/api.sql

## Shiva's versioning bundle commands
## Note: Requires Shiva's versioning bundle
show-version-status:
	docker-compose exec php php bin/console app:version:status

show-version-providers:
	docker-compose exec php php bin/console app:version:list-providers

#show-version-bump:
#	docker-compose exec php php bin/console app:version:bump

#### RELEASE BRANCHES
release-branch-minor:
	@echo
	@echo "Creating a release branch with a 'minor' version bump"
	@echo 
	@./_automation/create-release-branch.sh minor

release-branch-patch:
	@echo
	@echo "Creating a release branch with a 'patch' version bump"
	@echo 
	@./_automation/create-release-branch.sh patch