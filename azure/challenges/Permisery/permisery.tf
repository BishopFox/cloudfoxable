# resource group
resource "azurerm_resource_group" "permisery" {
  name      = "permiseryRG"
  location  = var.azure_region
}

resource "random_id" "suffix" {
  byte_length = 4
}

resource "random_id" "suffix2" {
  byte_length = 4
}

data "azurerm_client_config" "current" {}

# get IP needed for IP rules when creating key vault
data "http" "current_ip" {
  url = "https://icanhazip.com"
}

locals {
  user_ip = chomp(data.http.current_ip.response_body)
}

# create key vault
resource "azurerm_key_vault" "ctf" {
  name                        = "ctfkv${random_id.suffix.hex}"
  resource_group_name         = azurerm_resource_group.permisery.name
  location                    = azurerm_resource_group.permisery.location
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  sku_name                    = "standard"
  purge_protection_enabled    = false
  soft_delete_retention_days  = 7
  enable_rbac_authorization   = true

  network_acls {
    default_action = "Deny"
    bypass         = "AzureServices"
    ip_rules = concat(split(",", azurerm_linux_web_app.webapp.possible_outbound_ip_addresses), [local.user_ip])
  }

  depends_on = [azurerm_linux_web_app.webapp]
}

# put a flag in the key vault
resource "azurerm_key_vault_secret" "flag" {
  name         = "flag"
  value        = "FLAG{permisery:SSRFInTheCloudIsAlwaysFun}"
  key_vault_id = azurerm_key_vault.ctf.id
  depends_on   = [azurerm_role_assignment.kv_admin]
}

# provide admin rights to user under which terraform is running (should be azure admin user)
resource "azurerm_role_assignment" "kv_admin" {
  principal_id         = data.azurerm_client_config.current.object_id
  role_definition_name = "Key Vault Administrator"
  scope                = azurerm_key_vault.ctf.id
}

# provide reader permissions to ctf player
resource "azurerm_role_assignment" "guest_kv_reader" {
  principal_id         = var.player_object_id
  role_definition_name = "Key Vault Reader"
  scope                = azurerm_key_vault.ctf.id
}

# create a service plan (free tier), needed to create the web app
resource "azurerm_service_plan" "cloudfoxable" {
  name                = "cloudfoxable"
  resource_group_name = azurerm_resource_group.permisery.name
  location            = azurerm_resource_group.permisery.location
  os_type             = "Linux"
  sku_name            = "F1"
}

# create web app
resource "azurerm_linux_web_app" "webapp" {
  name                = "myfirstwebapp-${random_id.suffix2.hex}"
  resource_group_name = azurerm_resource_group.permisery.name
  location            = azurerm_resource_group.permisery.location
  service_plan_id     = azurerm_service_plan.cloudfoxable.id

  identity {
    type = "SystemAssigned"
  }

  site_config {
    application_stack {
      python_version = "3.9"
    }
    always_on = false
  }

  app_settings = {
    WEBSITES_ENABLE_APP_SERVICE_STORAGE = "false"
    SCM_DO_BUILD_DURING_DEPLOYMENT = "true"
    ENABLE_ORYX_BUILD = "true"
  }

  depends_on = [azurerm_service_plan.cloudfoxable]
}

# give ctf player reader permissions
resource "azurerm_role_assignment" "webapp_reader" {
  principal_id         = var.player_object_id
  role_definition_name = "Reader"
  scope                = azurerm_linux_web_app.webapp.id
}

# give the web app permission to read the key vault secrets
resource "azurerm_role_assignment" "webapp_secret_reader" {
  principal_id         = azurerm_linux_web_app.webapp.identity[0].principal_id
  role_definition_name = "Key Vault Secrets User"
  scope                = azurerm_key_vault.ctf.id
}

# defintion of the program running on the web app
resource "local_file" "app_py" {
  filename = "challenges/Permisery/data/app.py"
  content  = <<EOT
from flask import (Flask, request, render_template_string)
import requests
import os

app = Flask(__name__)

form_template = """
<!DOCTYPE html>
<html>
<head><title>Test Site</title></head>
<body>
  <p>Hello World! This is just a test site to generate web requests. Enter the target URL below. Custom headers can be included if needed.</p>
  <p>Additionally, for testing purposes the system environment variables can be found <a href="/env">here</a>.
  <form method="POST">
    <label>Target URL:</label><br>
    <input type="text" name="url" size="50"><br><br>

    <label>Custom Header 1:</label><br>
    Key: <input type="text" name="header1_key"> 
    Value: <input type="text" name="header1_value"><br><br>

    <label>Custom Header 2:</label><br>
    Key: <input type="text" name="header2_key"> 
    Value: <input type="text" name="header2_value"><br><br>

    <label>Custom Header 3:</label><br>
    Key: <input type="text" name="header3_key"> 
    Value: <input type="text" name="header3_value"><br><br>

    <input type="submit" value="Fetch">
  </form>

  {% if result %}
  <hr>
  <h3>Response from {{ url }}:</h3>
  <strong>Status:</strong> {{ status }}<br><br>
  <pre>{{ result }}</pre>
  {% endif %}
</body>
</html>
"""

@app.route("/", methods=["GET", "POST"])
def index():
    result = status = url = None

    if request.method == "POST":
        url = request.form.get("url")
        headers = {}

        for i in range(1, 4):
            key = request.form.get(f"header{i}_key")
            value = request.form.get(f"header{i}_value")
            if key and value:
                headers[key] = value

        try:
            response = requests.get(url, headers=headers, timeout=3)
            status = response.status_code
            result = response.text
        except Exception as e:
            status = "Error"
            result = str(e)

    return render_template_string(form_template, result=result, status=status, url=url)

@app.route("/env")
def show_env():
    env_vars = dict(os.environ)
    formatted = "<h2>Environment Variables</h2><pre>{}</pre>".format(
        "\n".join(f"{k}={v}" for k, v in sorted(env_vars.items()))
    )
    return formatted

if __name__ == '__main__':
   app.run()
EOT
}

# requirements.txt
resource "local_file" "requirements_txt" {
  filename = "challenges/Permisery/data/requirements.txt"
  content  = <<EOT
flask
gunicorn
requests
EOT
}

# zip everything up
data "archive_file" "app_zip" {
  type        = "zip"
  source_dir  = "challenges/Permisery/data/"
  output_path = "challenges/Permisery/zip/app.zip"

  depends_on = [resource.local_file.requirements_txt, resource.local_file.app_py]
}

# deploy the zip to the webapp
resource "null_resource" "zip_deploy" {
  provisioner "local-exec" {
    command = <<EOT
az webapp deploy --resource-group ${azurerm_resource_group.permisery.name} \
  --name ${azurerm_linux_web_app.webapp.name} \
  --src-path ${data.archive_file.app_zip.output_path} \
  --type zip
EOT
}

  depends_on = [azurerm_linux_web_app.webapp, data.archive_file.app_zip]
}