# Azure Developer CLI (azd) Rails on Azure starter with Bicep and Postgresql 

A starter blueprint for getting your Rails application up on Azure using [Azure Developer CLI](https://learn.microsoft.com/en-us/azure/developer/azure-developer-cli/overview) (azd). The Rails application is deployed in Azure Container Apps and uses an Azure Postgresql database. The starter uses Infrastructure as Code assets in [Bicep](https://aka.ms/bicep) to get your application up and running quickly.

The rails application has been created by running the following command:

    rails new --database=postgresql --name=azure-rails-starter src
    rm -rf src/.git

The following assets have been provided:

- Infrastructure-as-code (IaC) Bicep files under the `infra` folder that demonstrate how to provision resources and setup resource tagging for azd.
- A [dev container](https://containers.dev) configuration file under the `.devcontainer` directory that installs infrastructure tooling by default. This can be readily used to create cloud-hosted developer environments such as [GitHub Codespaces](https://aka.ms/codespaces).
  - Ruby 3.3.0 
  - GitHub Copilot
- Continuous deployment workflows for CI providers such as GitHub Actions under the `.github` directory, and Azure Pipelines under the `.azdo` directory that work for most use-cases.
- A freshly created Rails 7.1.3 application under directory `src`. The application has been created with `rails new --database=postgresql --name=azure-rails-starter src`. If you need a different setup just delete `src` and re-run the command with a different version of Rails, application name or database backend.

## Next Steps

3. Run `azd package` to validate that all service source code projects can be built and packaged locally.


Run `azd provision` whenever you want to ensure that changes made are applied correctly and work as expected.


1. Set up [application settings](#application-settings) for the code running in Azure to connect to other Azure resources.
1. If you are accessing sensitive resources in Azure, set up [managed identities](#managed-identities) to allow the code running in Azure to securely access the resources.
1. If you have secrets, it is recommended to store secrets in [Azure Key Vault](#azure-key-vault) that then can be retrieved by your application, with the use of managed identities.
1. Configure [host configuration](#host-configuration) on your hosting platform to match your application's needs. This may include networking options, security options, or more advanced configuration that helps you take full advantage of Azure capabilities.

When changes are made, use azd to validate and apply your changes in Azure, to ensure that they are working as expected:

- Run `azd up` to validate both infrastructure and application code changes.
- Run `azd deploy` to validate application code changes only.

### Step 4: Up to Azure

Finally, run `azd up` to run the end-to-end infrastructure provisioning (`azd provision`) and deployment (`azd deploy`) flow. Visit the service endpoints listed to see your application up-and-running!

## Additional Details

The following section examines different concepts that help tie in application and infrastructure.

### Application settings

It is recommended to have application settings managed in Azure, separating configuration from code. Typically, the service host allows for application settings to be defined.

- For `appservice` and `function`, application settings should be defined on the Bicep resource for the targeted host. Reference template example [here](https://github.com/Azure-Samples/todo-nodejs-mongo/tree/main/infra).
- For `aks`, application settings are applied using deployment manifests under the `<service>/manifests` folder. Reference template example [here](https://github.com/Azure-Samples/todo-nodejs-mongo-aks/tree/main/src/api/manifests).

### Managed identities

[Managed identities](https://learn.microsoft.com/en-us/azure/active-directory/managed-identities-azure-resources/overview) allows you to secure communication between services. This is done without having the need for you to manage any credentials.

### Azure Key Vault

[Azure Key Vault](https://learn.microsoft.com/en-us/azure/key-vault/general/overview) allows you to store secrets securely. Your application can access these secrets securely through the use of managed identities.


## Getting started developing

### Running Rails commands

Move to the `src` directory:

    cd src

Run the Rails server:

    bin/rails server

Run the Rails console:

    bin/rails console 

Run the Rails migration command:

    bin/rails db:migrate

### Connecting to the Postgresql database

   psql $DATABASE_URL


