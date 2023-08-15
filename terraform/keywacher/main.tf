//module "fs" {
//source = "./modules/Azure_FileShare/"
//}

//module "sb" {
//source = "./modules/Azure_ServiceBusNamespace/"
//}

// module "redis" {
// source = "./modules/Azure_Redis/"
// }


# Storage account creation for boot diagonstics
resource "azurerm_storage_account" "vmbootdiagnostic" {
  name                     = var.storage_account_name_vm
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  cross_tenant_replication_enabled = false
  allow_nested_items_to_be_public  = false
  tags = var.tags
  lifecycle {
    ignore_changes = [
      tags,
    ]
  }
}

# Module 1: Creating microservices server  --2 
module "_appservers" {
    
    source = "../modules/windows_vm_pool/"
    # its depends on storageaccount
    depends_on = [azurerm_storage_account.vmbootdiagnostic]
    storage_account_name      = azurerm_storage_account.vmbootdiagnostic.name
    resource_group_name       = var.resource_group_name
    location                  = var.location
    virtual_network_name      = var.virtual_network_name
    vnet_resource_group_name  = var.vnet_resource_group_name
    subnet_name               = var.subnet_name 
    license_type              = var.license_type
    virtual_machine_names     = var.vms_app
    virtual_machine_size       = var.virtual_machine_size_app
    windows_distribution_name = var.vm_windows_distribution_name
    keyvault_name             = var.keyvault_name
    keyvault_resource_group_name = var.keyvault_resource_group_name
    #tags = var.tags_microservice
    tags =  merge(var.tags, {"ROLE": "Microservice" })
}


# Module 2: Creating SQL Server and DB's 
module "_sqlservers" {
    
    source = "../modules/MSSQLAzure/"
    # its depends on storageaccount
    storage_account_name = var.storage_account_name_sql
    resource_group_name  = var.resource_group_name
    location             = var.location
    sqlserver_name       = var.sqlserver_name
    database_name        = var.database_name
    keyvault_name        = var.keyvault_name
    keyvault_resource_group_name = var.keyvault_resource_group_name
    tags = var.tags
}

# Module 7: creating filsshare 
module "_fileshare" {
 source = "../modules/Azure_FileShare/"
 resource_group_name = var.resource_group_name
 location = var.location
 storage_account_name = var.storage_account_name_fs
 tags = var.tags
 share_names          = var.fileshares
  files_auth = {
    directory_type = var.fileshare_auth.directory_type
    active_directory = {
      domain_guid         = var.fileshare_auth.active_directory.domain_guid
      domain_name         = var.fileshare_auth.active_directory.domain_name
      domain_sid          = var.fileshare_auth.active_directory.domain_sid
      forest_name         = var.fileshare_auth.active_directory.forest_name
      netbios_domain_name = var.fileshare_auth.active_directory.netbios_domain_name
      storage_sid         = var.fileshare_auth.active_directory.storage_sid
    }
  }
 }
  # Module 8: Creating App Inisights

module "AppInsights" {
source = "../modules/Azure_App_Insights/"

app_insights_name = var.app_insights_name
resource_group_name = var.resource_group_name
application_type    = "web"
tags                = var.tags
}