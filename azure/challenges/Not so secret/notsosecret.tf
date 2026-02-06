resource "random_id" "suffix" {
    byte_length = 5
}

resource "random_id" "suffix2" {
    byte_length = 5
}

# RBAC Permissions
resource "azurerm_role_assignment" "storage_blob_reader" {
  principal_id          = var.player_object_id
  role_definition_name  = "Storage Blob Data Reader"
  scope                 = azurerm_storage_account.storage_account_1.id
}

resource "azurerm_role_assignment" "reader" {
  principal_id         = var.player_object_id
  role_definition_name = "Reader"
  scope                = azurerm_storage_account.storage_account_1.id
}

# create storage account 1
resource "azurerm_storage_account" "storage_account_1" {
  name                     = "notsosecret${random_id.suffix.hex}"
  resource_group_name      = var.resource_group_name
  location                 = var.resource_group_location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# create storage account 2
resource "azurerm_storage_account" "storage_account_2" {
  name                     = "notsosecret${random_id.suffix2.hex}"
  resource_group_name      = var.resource_group_name
  location                 = var.resource_group_location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  allow_nested_items_to_be_public = true
}

# create container 1 in storage account 1
resource "azurerm_storage_container" "storage_container_1" {
  name                  = "files"
  storage_account_id    = azurerm_storage_account.storage_account_1.id
  container_access_type = "private"
}

# create file 1 in container
resource "azurerm_storage_blob" "file1" {
  name                   = "cinderella.txt"
  type                   = "Block"
  source                 = "challenges/Not so secret/data/cinderella.txt"
  storage_account_name   = azurerm_storage_account.storage_account_1.name
  storage_container_name = azurerm_storage_container.storage_container_1.name
  content_type           = "text/plain"
}

# create file 2 in container
resource "azurerm_storage_blob" "file2" {
  name                   = "jack_and_the_beanstalk.txt"
  type                   = "Block"
  source                 = "challenges/Not so secret/data/jack_and_the_beanstalk.txt"
  storage_account_name   = azurerm_storage_account.storage_account_1.name
  storage_container_name = azurerm_storage_container.storage_container_1.name
  content_type           = "text/plain"
}

# create file 3 in container
resource "azurerm_storage_blob" "file3" {
  name                   = "little_red_riding_hood.txt"
  type                   = "Block"
  source                 = "challenges/Not so secret/data/little_red_riding_hood.txt"
  storage_account_name   = azurerm_storage_account.storage_account_1.name
  storage_container_name = azurerm_storage_container.storage_container_1.name
  content_type           = "text/plain"
}

# create file 4 in container
resource "azurerm_storage_blob" "file4" {
  name                   = "snow_white.txt"
  type                   = "Block"
  source                 = "challenges/Not so secret/data/snow_white.txt"
  storage_account_name   = azurerm_storage_account.storage_account_1.name
  storage_container_name = azurerm_storage_container.storage_container_1.name
  content_type           = "text/plain"
}

# create container 2 in storage account 1
resource "azurerm_storage_container" "storage_container_2" {
  name                  = "contacts"
  storage_account_id    = azurerm_storage_account.storage_account_1.id
  container_access_type = "private"
}

# create file 5 in container 2

resource "azurerm_storage_blob" "file5" {
  name                   = "contacts.csv"
  type                   = "Block"
  source                 = "challenges/Not so secret/data/contacts.csv"
  storage_account_name   = azurerm_storage_account.storage_account_1.name
  storage_container_name = azurerm_storage_container.storage_container_2.name
  content_type           = "text/csv"
}

# create container 3 in storage account 1
resource "azurerm_storage_container" "storage_container_3" {
  name                  = "policies"
  storage_account_id    = azurerm_storage_account.storage_account_1.id
  container_access_type = "private"
}

# create file 6 in container 3
resource "azurerm_storage_blob" "file6" {
  name                   = "employeePolicy.txt"
  type                   = "Block"
  source                 = "challenges/Not so secret/data/employeePolicy.txt"
  storage_account_name   = azurerm_storage_account.storage_account_1.name
  storage_container_name = azurerm_storage_container.storage_container_3.name
  content_type           = "text/plain"
}

# create container 4 in storage account 1
resource "azurerm_storage_container" "storage_container_4" {
  name                  = "employees"
  storage_account_id    = azurerm_storage_account.storage_account_1.id
  container_access_type = "private"
}

# create file 7 in container 4
resource "azurerm_storage_blob" "file7" {
  name                   = "employees.csv"
  type                   = "Block"
  source                 = "challenges/Not so secret/data/employees.csv"
  storage_account_name   = azurerm_storage_account.storage_account_1.name
  storage_container_name = azurerm_storage_container.storage_container_4.name
  content_type           = "text/csv"
}

# create container 5 in storage account 1
resource "azurerm_storage_container" "storage_container_5" {
  name                  = "assets"
  storage_account_id    = azurerm_storage_account.storage_account_1.id
  container_access_type = "private"
}

# create local file with data
resource "local_file" "assets_csv" {
  content  = <<EOT
Asset,Type,Details
prodDB1,Database,Production Database containing employees
prodDB2,Database,Production Database containing contacts
prodDB3,Database,Production Database containing HR data
prodDB4,Database,Production Database containing assets
adminVM,Virtual Machine,VM for admin functionality
devVM,Virtual Machine,VM for developer use
jumpbox,Virtual Machine,Jumpbox to access private network
prodLB1,Load Balancer,Production load balancer East
prodLB2,Load Balancer,Production load balancer West
stageLB1,Load Balancer,Stage load balancer East
stageLB2,Load Balancer,Stage load balancer West
internalEast,Virtual Network,Internal network East
internalWest,Virtual Network,Internal network West
private,Virtual Network,Private network
${azurerm_storage_account.storage_account_1.name},Storage Account,Storage account East
${azurerm_storage_account.storage_account_2.name},Storage Account,Storage account West
files,Container,${azurerm_storage_account.storage_account_1.name}
contacts,Container,${azurerm_storage_account.storage_account_1.name}
policies,Container,${azurerm_storage_account.storage_account_1.name}
employees,Container,${azurerm_storage_account.storage_account_1.name}
assets, Container,${azurerm_storage_account.storage_account_1.name}
sensitivefiles,Container,${azurerm_storage_account.storage_account_2.name}
EOT
  filename = "challenges/Not so secret/data/assets.csv"
}

# create file 8 in container 5
resource "azurerm_storage_blob" "file8" {
  name                   = "assets.csv"
  type                   = "Block"
  source                 = "challenges/Not so secret/data/assets.csv"
  storage_account_name   = azurerm_storage_account.storage_account_1.name
  storage_container_name = azurerm_storage_container.storage_container_5.name
  content_type           = "text/csv"
  depends_on             = [local_file.assets_csv]
}

# create container 6 in storage account 2
resource "azurerm_storage_container" "storage_container_6" {
  name                  = "sensitivefiles"
  storage_account_id    = azurerm_storage_account.storage_account_2.id
  container_access_type = "container"
}

# create file 9 (flag) in container 6
resource "azurerm_storage_blob" "file9" {
  name                   = "flag.txt"
  type                   = "Block"
  source                 = "challenges/Not so secret/data/flag.txt"
  storage_account_name   = azurerm_storage_account.storage_account_2.name
  storage_container_name = azurerm_storage_container.storage_container_6.name
  content_type           = "text/plain"
}
