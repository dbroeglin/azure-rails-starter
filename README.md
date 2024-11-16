---
name: Azure Rails Starter
description: Sample Rails application deployed through Azure Developer CLI (azd) on Azure Container App and Azure Database for PostgreSQL
languages:
- ruby
- bicep
- azdeveloper
products:
- azure-container-apps
- azure-database-postgresql
- azure-key-vault
- azure
page_type: sample
urlFragment: azure-rails-starter
---

# Deploy a Rails (Ruby) web app with PostgreSQL In Azure Container Apps 


[![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://codespaces.new/dbroeglin/azure-rails-starter?quickstart=1)

This is a starter blueprint for getting your Rails application up and running on Azure using [Azure Developer CLI](https://learn.microsoft.com/en-us/azure/developer/azure-developer-cli/overview) (azd). The Rails application is deployed in an Azure Container App and uses an Azure Postgresql database. The starter uses Infrastructure as Code assets in [Bicep](https://aka.ms/bicep) to get your application up and running quickly.

![Azure Rails Starter Overview](assets/Azure%20Rails%20Starter%20Overview.png)

The following assets have been provided:

- Infrastructure-as-code (IaC) Bicep files under the `infra` folder that demonstrate how to provision resources and setup resource tagging for azd.
- A [dev container](https://containers.dev) configuration file under the `.devcontainer` directory that installs infrastructure tooling by default. This can be readily used to create cloud-hosted developer environments such as [GitHub Codespaces](https://aka.ms/codespaces).
  - Ruby 3.3.0 
  - GitHub Copilot
  - Postgresql running in a container (for development)
  - Redis running in a container (for development)
- Continuous deployment workflows for CI providers such as GitHub Actions under the `.github` directory, and Azure Pipelines under the `.azdo` directory that work for most use-cases.
- A freshly created Rails 7.1.3 application under directory `src`.


### Getting the Rails app up and running in Azure

Just run `azd up` to run the end-to-end infrastructure provisioning (`azd provision`) and deployment (`azd deploy`) flow. Visit the service endpoint listed to see your application up-and-running!

Quick start:

```bash
SECRET_KEY_BASE="$(src/bin/rails secret)" \
RAILS_MASTER_KEY="$(cat src/config/master.key)" \
azd up
```

## Additional Details

The following section examines different concepts that help tie in application and infrastructure.

### Application settings

It is recommended to have application settings managed in Azure, separating configuration from code. Typically, the service host allows for application settings to be defined.

- Application settings should be defined on the Bicep resource for the Azure Container App. See [main.bicep](./infra/rails.bicep#L43) for an example setting environment variables and using secrets stored in Azure Key Vault.
- Environment variables for your developer environment (Dev Containers or Codespaces) can be defined in [.decontainer/Dockerfile](.devcontainer/Dockerfile).

### Managed identities

[Managed identities](https://learn.microsoft.com/en-us/azure/active-directory/managed-identities-azure-resources/overview) allows you to secure communication between services. This is done without having the need for you to manage any credentials. It is used between Azure Container Apps and Azure Key Vault to automatically retrieve secrets.s

### Azure Key Vault

[Azure Key Vault](https://learn.microsoft.com/en-us/azure/key-vault/general/overview) allows you to store secrets securely. Your application can access these secrets securely through the use of managed identities.

## Getting started with Rails development

### Provisioning & deploying with Azure Developer CLI

When changes are made, use azd to validate and apply your changes in Azure, to ensure that they are working as expected:

- Run `azd up` to validate both infrastructure and application code changes.
- Run `azd deploy` to validate application code changes only.

### Running Rails commands

Move to the `src` directory:

```bash
cd src
```

Run the Rails server:

```bash
bin/rails server
```

Run the Rails console:

```bash
bin/rails console 
```

Run the Rails migration command:

```bash
bin/rails db:migrate
```

### Connecting to the Postgresql database

```bash
psql $DATABASE_URL
```

### Re-creating the Rails application

The rails application has been created by running the following command:

```bash
rails new --database=postgresql --name=azure-rails-starter src
rm -rf src/.git
cd src
sed -i '' 's/# root.*$/root "home#index"/' config/routes.rb
sed -i '' '/azure_rails_starter_production$/,/DATABASE_PASSWORD/c\
    url: <%= ENV["DATABASE_URL"] %>
' config/database.yml
cat > app/controllers/home_controller.rb <<EOF
class HomeController < ApplicationController
  def index
    render plain: 'Hello World!'
  end
end
EOF
```

### Obtain a shell in the Azure Container App 

```bash
. ./.env
az containerapp exec --name $SERVICE_RAILS_NAME --resource-group $AZURE_RESOURCE_GROUP_NAME
```

This can be useful to apply `bin/rails db:migrate` commands or access the Rails console through `bin/rails console`. Note that the default `bin/docker-entrypoint` already runs `bin/rails db:prepare`.

### Clean up resources

```bash
    azd down
```

If you want to make sure you can recreate the same environment, KeyVault needs to be purged:

```bash
    azd down --purge
```

## Security consideration

In this repository `src/config/master.key` has been committed to simplify deployment of the sample application. If you plan on building from the sample app please delete `config/master.key` and `config/credentials.yml.enc`. Commit the changes. Then run `bin/rails credentials:edit`. 

## Getting help

Sometimes deployment fails because the PostgreSQL resource is still busy and extensions cannot yet be applied. In a case like that just re-run the deployment.

If you're working with this project and running into issues, please post an Issue by clicking on the link above.
