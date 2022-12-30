# LAB

## Part 3: Create and deploy web app client

1. Inside "web" directory create new file "index.html" and paste it's content from lab's file.
2. Go to root directory of your project
3. Install Static Web Site Azure CLI:
```
npm install -g @azure/static-web-apps-cli 
```
4. Being at the root folder of your project execute:
```
swa init
```
Make sure these setting are correct:
- appLocation: web
- apiLocation: api
5. Test your app locally:
```
swa start
```
6. In "iac" directory create new file "swa.tf" and paste this content:
```
resource "azurerm_static_site" "example" {
  name                = "${var.prefix}-SWA"
  location            = "${var.location}"
  resource_group_name = "${var.rgname}"
  sku_tier            = "Standard"
  sku_size            = "Standard"
}
```
7. Deploy it to Azure:
```
terraform plan
terraform apply -auto-approve
```
6. Create new file ".gitignore" with content:
```
iac/.terraform
iac/.terraform.lock.hcl
.vscode
```
7. Open "github.com" and create new empty repository for your project.
8. Being at the root folder of your project, initialize git repo:
```
git init
git add api iac web
git commit -m "first commit"
git branch -M main
git remote add origin YOUR_REPO_URL
git push -u origin main
```
8. From Azure Portal, static web site resource copy deployment token.
9. In the root folder of the repo create ".github/workflows" directory and inside cerate new file "deploy-to-swa.yaml" with content:
```
name: Azure Static Web Apps CI/CD

on:
  push:
    branches:
      - main
  pull_request:
    types: [opened, synchronize, reopened, closed]
    branches:
      - main

jobs:
  build_and_deploy_job:
    if: github.event_name == 'push' || (github.event_name == 'pull_request' && github.event.action != 'closed')
    runs-on: ubuntu-latest
    name: Build and Deploy Job
    steps:
      - uses: actions/checkout@v2
        with:
          submodules: true
      - name: setup vue environment file
        run: |
          echo "VUE_APP_NOT_SECRET_CODE=some_value" >  $GITHUB_WORKSPACE/.env
      - name: Build And Deploy
        id: builddeploy
        uses: Azure/static-web-apps-deploy@v0.0.1-preview
        with:
          azure_static_web_apps_api_token: STATIC_APP_TOKEN
          repo_token: $${{ secrets.GITHUB_TOKEN }} # Used for Github integrations (i.e. PR comments)
          action: "upload"
          ###### Repository/Build Configurations - These values can be configured to match you app requirements. ######
          # For more information regarding Static Web App workflow configurations, please visit: https://aka.ms/swaworkflowconfig
          app_location: "web" # App source code path
          api_location: "api" # Api source code path - optional
          output_location: "${ output_location }" # Built app content directory - optional
          ###### End of Repository/Build Configurations ######

  close_pull_request_job:
    if: github.event_name == 'pull_request' && github.event.action == 'closed'
    runs-on: ubuntu-latest
    name: Close Pull Request Job
    steps:
      - name: Close Pull Request
        id: closepullrequest
        uses: Azure/static-web-apps-deploy@v0.0.1-preview
        with:
          azure_static_web_apps_api_token: STATIC_APP_TOKEN
          action: "close"

```
10. Make these changes:
- replace STATIC_APP_TOKEN with your deployment token
11. Commit and push new file
12. Check if app was deployed successfully
13. Change the "api_location" parameter to empty ("") and commit file again.
14. Go to Azure Portal and link you static web app with Azure Function.