# Remote state in Azure Storage. Create this storage account/container out-of-band
# (or via a bootstrap script) before first `terraform init`, since state can't
# bootstrap its own backend.
#
#   az group create -n rg-tfstate -l centralindia
#   az storage account create -n sttfstatedocplat -g rg-tfstate -l centralindia --sku Standard_LRS --min-tls-version TLS1_2
#   az storage container create -n tfstate --account-name sttfstatedocplat --auth-mode login

terraform {
  backend "azurerm" {
    resource_group_name  = "rg-tfstate"
    storage_account_name = "sttfstatedocplat"
    container_name        = "tfstate"
    key                   = "dev.terraform.tfstate"
    use_azuread_auth      = true
  }
}
