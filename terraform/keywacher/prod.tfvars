env                             = ""
location                        = ""
resource_group_name             = ""  
keyvault_resource_group_name    = ""
app_name                        = ""
vnet_resource_group_name        = ""
subnet_name                     = ""
virtual_network_name            = ""
license_type                    = "Windows_Server"
load_distribution                = "SourceIPProtocol"
virtual_machine_size             = "Standard_D4s_v4"
virtual_machine_size_app         = "Standard_E16-4s_v3" #"Standard_E16-4as_v5" E16-4s_v3
vms_app                       = [

    ]
vm_windows_distribution_name = "windows2019dc"
keyvault_name                = ""
storage_account_name_vm      = ""
storage_account_name_sql     = ""
storage_account_name_fs      = ""
sqlserver_name               = ""
database_name                = []
app_insights_name            = ""

fileshares =  {
     "" = "250"   //fileshare share name - fsshn
   }


fileshare_auth = {
  directory_type = "AD"
  active_directory = {
    domain_guid         = ""
    domain_name         = ""
    domain_sid          = ""
    forest_name         = ""
    netbios_domain_name = "US"
    storage_sid         = ""
  }
}      