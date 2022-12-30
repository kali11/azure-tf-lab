locals {
  api_token_var = "AZURE_STATIC_WEB_APPS_API_TOKEN"
}

variable "github_token" {}
variable "github_owner" {}

provider "github" {
  token = var.github_token
  owner = var.github_owner
}

resource "github_actions_secret" "test" {
  repository      = "REPO_NAME"
  secret_name     = local.api_token_var
  plaintext_value = azurerm_static_site.example.api_key
}

resource "github_repository_file" "my file" {
  repository = "REPO_NAME"
  branch     = "main"
  file       = ".github/workflows/azure-static-web-app.yml"
  content = templatefile("./azure-static-web-app.tpl",
    {
      app_location    = "web"
      output_location = ""
      api_token_var   = local.api_token_var
    }
  )
}
