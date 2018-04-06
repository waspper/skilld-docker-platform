# Docker-based stack for Skilld Platform projects

Docker containers to manage projects hosted in Platform by Skilld. This stack is based on wodby/docker4drupal. More information 
may be found at https://wodby.com/stacks/drupal/docs/local and https://github.com/wodby/docker4drupal.

Currently, this template is in Alpha state. Some improvements/tweaks may be needed.

## Introduction

Platform is a PaaS provider. You can use this project to build your local development instances.
 
## Before you start

You must have access to the Platform.sh account (https://accounts.platform.sh). There, go to "Account settings", select
"SSH keys" and add there your public key. Usually, this key is found at ~/.ssh/id_rsa.pub.

## Troubleshooting adding keys

Sometimes, Platform says that your keys is invalid. In this case, you need to create a new one specifically for this purpose.

By executing:

platform ssh-key:add

It will ask you if your default (if exists) key should be added. Say "No", and create a new one. Then Platform CLI will add it to the
account.

Once added, you need to tell your SSH agent that it should use your key, too. Let's assume that you created a private and public keys:

- ~/.ssh/id_rsa.2
- ~/.ssh/id_rsa.2.pub

Add the first one to your agent:

ssh-add ~/.ssh/id_rsa.2

Ensure your key was added:

ssh-add -l

If not added permanently, then shou'll need to execute the "ssh-add" command every time you restart your PC.

## Configure needed environment variables

The file .env.default will be copied to .env. This last one will let you to customize your needed settings. Most important are:

- PROJECT_NAME: The unique-machine name for your project. Example: mysite.
- PROJECT_BASE_URL: If you wish to have a nice URL for your local (example: mysite.docker.localhost), then edit your /etc/hosts and add:
    127.0.0.1        mysite.docker.localhost
- PLATFORM_PROJECT: The project identifier in Platform (example: hs50q40ab9yrs). You can get this value into the Platform project dashboard, or from your CLI command:
    platform get hs50q40ab9yrs -e site-dev
- PLATFORM_ENVIRONMENT: Environment/branch to fetch (example: site-dev). You can get this value into the Platform project dashboard, or from your CLI command:
    platform get hs50q40ab9yrs -e site-dev

## Available Makefile target rules

- make: Build the whole project.
- make up: Download/pull docker images and build containers.
- make down: Wraper for "top" and useful commands.
- make stop: Stop containers.
- make prune: Remove containers.
- make ps: Show information about containers.
- make shell: Login into the PHP container.
- make prepare: Download project from platform, build it and other stuff.
- make install: Wrapper for installation commands.
- make ip: Show container IPs.
- make platform-build: Enter to the platform folder, and build project.
- make sources: Copy files, modules and any needed file from a versioned folder into the build folder.
- make db-fetch: Download a fresh db dump from Platform.
- make db-import: Import the downloaded database into the Mariadb container. The SQL file must be placed at docker-entrypoint-initdb.d/$(DB_NAME).sql.
- make cc: Run "drush cc all" for cache clearing.
- make clean: Delete the platform folder.
