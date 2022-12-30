# LAB

## Part 1: Deploying Azure Services as a Code using Terraform

1. Create project structure. In the root directory of your project create 3 subsirectories:
- "iac" - for terraform code
- "api" - for Azure Function backend
- "web" - for web app

2. Enter "iac" dir

3. Create new files: "main.tf", "variables.tf", "outputs.tf"

4. In "variables.tf" paste:
```
variable "prefix" {
  type        = string
  description = "The prefix used for all resources in this example. (A bunch of alphanumeric characters.)"
}

variable "location" {
  type        = string
  description = "The Azure location where all resources in this example should be created"
}

variable "rgname" {
  type        = string
  description = "Azure resource group name"
}
```
5. In "main.tf" paste:
```
provider "azurerm" {
  features {}
}

resource "azurerm_storage_account" "example" {
  name                     = "${var.prefix}storageacct"
  resource_group_name      = "${var.rgname}"
  location                 = "${var.location}"
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_application_insights" "example" {
  name                = "${var.prefix}-appinsights"
  resource_group_name = "${var.rgname}"
  location            = "${var.location}"
  application_type    = "web"
}

resource "azurerm_service_plan" "example" {
  name                = "${var.prefix}-sp"
  location            = "${var.location}"
  resource_group_name = "${var.rgname}"
  os_type             = "Linux"
  sku_name            = "Y1"
}

resource "azurerm_linux_function_app" "example" {
  name                = "${var.prefix}-LFA"
  location            = "${var.location}"
  resource_group_name = "${var.rgname}"
  service_plan_id     = azurerm_service_plan.example.id

  storage_account_name       = azurerm_storage_account.example.name
  storage_account_access_key = azurerm_storage_account.example.primary_access_key

  site_config {
    application_insights_connection_string = azurerm_application_insights.example.connection_string
    application_stack {
      node_version = 18
    }
  }

  app_settings = {
    "SOME_KEY" = "SOME_VALUE"
  }
}
```
6. In "outputs.tf" paste:
```
output "app_name" {
  value = azurerm_linux_function_app.example.name
}
```
7. Deploy all resources to Azure: (As a location type "westeurope" and as a rgname - name of your resoure group)
```
terraform init
terraform plan
terraform apply
```
8. Create new file "terraform.tfvars"
9. Enter this content:
```
prefix = "YOUR_UNIQUE_PREFIX"
location = "westeurope"
rgname = "YOUR_RG_NAME"
```
10. Add Azure Key Vault:
```
data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "example" {
  name                        = "${var.prefix}akv"
  location                    = "${var.location}"
  resource_group_name         = "${var.rgname}"
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false

  sku_name = "standard"
  }
```
11. Deploy and check if changed were made.
12. Add System-assigned managed identity to App Service resource:
```
  identity {
    type = "SystemAssigned"
  }
```
13. Get app's managed identity:
```
data "azuread_service_principal" "app_sp" {
  display_name = azurerm_linux_function_app.example.name
  depends_on   = [
    azurerm_linux_function_app.example
  ]
}
```
14. Assign proper permissions to key vault:
```
resource "azurerm_key_vault_access_policy" "kv_read_access_policy" {
  key_vault_id = azurerm_key_vault.example.id

  tenant_id = data.azurerm_client_config.current.tenant_id  
  object_id = data.azuread_service_principal.app_sp.id

  secret_permissions = [
    "Get",
    "List"
  ]
}

resource "azurerm_key_vault_access_policy" "example" {
  key_vault_id = azurerm_key_vault.example.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id

  secret_permissions = [
    "Get",
    "List",
    "Set",
    "Delete"
  ]
}
```
15. Now we want to add TF code to deploy Azure SQL database. 
16. First add two variables in "variables.tf" file:
```
variable "dbadmin" {
  type        = string
}

variable "dbadminpass" {
  type        = string
}
```
17. Add variable values in "terraform.tfvars":
```
dbadmin = "demoadmin"
dbadminpass = "Passw0rd1!123"
```
18. Create ne file "db.tf" with this content:
```
resource "azurerm_mssql_server" "example" {
  name                         = "${var.prefix}-sqlsvr"
  location                     = "${var.location}"
  resource_group_name          = "${var.rgname}"
  version                      = "12.0"
  administrator_login          = "${var.dbadmin}"
  administrator_login_password = "${var.dbadminpass}"
  minimum_tls_version          = "1.2"
}

resource "azurerm_mssql_database" "example" {
  name                          = "tododb"
  server_id                     = azurerm_mssql_server.example.id
  collation                     = "SQL_Latin1_General_CP1_CI_AS"
  max_size_gb                   = 1
  min_capacity                  = 0.5
  read_scale                    = false
  sku_name                      = "GP_S_Gen5_1"
  zone_redundant                = false
  auto_pause_delay_in_minutes   = 60
}

resource "azurerm_mssql_firewall_rule" "example" {
  name                = "allow-azure-services"
  server_id           = azurerm_mssql_server.example.id
  start_ip_address    = "0.0.0.0"
  end_ip_address      = "0.0.0.0"
}
```
19. Deploy database:
```
terraform plan
terraform apply -auto-approve
```
20. Add proper configuration to Azure App Service. In main.tf, in "azurerm_linux_function_app"  paste as a property:
```
  app_settings = {
    "db_server" = "${azurerm_mssql_server.example.name}.database.windows.net"
    "db_database" = azurerm_mssql_database.example.name
    "db_user" = "@Microsoft.KeyVault(VaultName=${azurerm_key_vault.example.name};SecretName=dbuser)"
    "db_password" = "@Microsoft.KeyVault(VaultName=${azurerm_key_vault.example.name};SecretName=dbpass)"
  }
```
21. Add new output to "outputs.tf":
```
ouput "server_name" {
  value = azurerm_mssql_server.example.name
}
```
22. Deploy everything using:
```
terraform plan
terraform apply -auto-approve
```
Note down the server name from outputs.

23. Now, let's prepare database schema. Using Azure Portal go to your SQL database, open Query editor and execute whole "database/create.sql" query. In order to log in to database you will need to add your IP to server firewall rules.