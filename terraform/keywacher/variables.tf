variable "env" {
  description = "deployment environment. Eg. 'dev', 'stg', 'prod'"
  type = string 
}

variable "app_name" {
  description = "application name. k1ml,k1 mg"
  type = string 
}

variable "location" {
  description = "location of the resources should be created"
  type = string
  
}

variable "resource_group_name" {
  description = "RG of the resources should be created"
  type = string
}

variable "keyvault_resource_group_name" {
   description = "RG of the resources used for key vault"
  type = string
}

variable "subnet_name" {
  description = "subnet name of the resources should be created"
  type = string 
}

variable "virtual_network_name" {
  description = "RG of the resources should be created"
  type = string 
}

variable "vnet_resource_group_name" {
  description = "RG of the resources should be created"
  type = string 
}

variable "storage_account_name_vm" {
  description = "storage account for vm diagonsotics"
  type = string 
}

variable "storage_account_name_sql" {
  description = "storage account for sql server"
  type = string 
}

variable "storage_account_name_fs" {
  description = "storage account for fils share"
  type = string 
}

# VM variables

variable "license_type" {
  description = "Specifies the type of on-premise license which should be used for this Virtual Machine. Possible values are None, Windows_Client and Windows_Server."
  type = string 
}

variable "virtual_machine_size" {
  description = "Specifies the type of on-premise license which should be used for this Virtual Machine. Possible values are None, Windows_Client and Windows_Server."
  type        = string
}

variable "virtual_machine_size_app" {
  description = "Specifies the type of on-premise license which should be used for this Virtual Machine. Possible values are None, Windows_Client and Windows_Server."
  type        = string
}

variable "virtual_machine_size_web" {
  description = "Specifies the type of on-premise license which should be used for this Virtual Machine. Possible values are None, Windows_Client and Windows_Server."
  type        = string
}


variable "vm_windows_distribution_name" {
  description = "windows distribution name"
  type = string 
}

variable "vms_web" {
  description = "Windows Vms created for web services"
  type = set(string)
}

variable "vms_app" {
  description = "Windows Vms created for app services"
  type = set(string)
}


variable "keyvault_name" {
  description = "keyvault name"
  type = string 
}

# SQL  variables


variable "sqlserver_name" {
  description = "sqlserver name"
  type = string 
}

variable "database_name" {
  description = "databses names for SQL server"
  type = list(string)
}

variable "app_insights_name" {
  description = "app insights name"
  type = string 
}

variable "fileshares" {
  description = "File share connfig name and size"
  type        = map(string)
}
variable "fileshare_auth" {
  type = object({
    directory_type = string
    active_directory = object({
      domain_guid         = string
      domain_name         = string
      domain_sid          = string
      forest_name         = string
      netbios_domain_name = string
      storage_sid         = string
    })
  })
}

variable "load_distribution" {
  description = "Specifies the load balancing distribution type to be used by the Load Balancer"
}



