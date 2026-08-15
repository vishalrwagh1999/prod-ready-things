terraform {
  required_version = ">= 1.3.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
  }
  backend "azurerm" {
    resource_group_name  = "tfstate-rg"
    storage_account_name = "tfstatevishal"
    container_name       = "tfstate-files-azure-devops"
    key                  = "acr/dev/terraform.tfstate"
  }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy = false
    }
  }
  subscription_id = var.subscription_id
}

# -------------------------------------------------------------------
# Resource Group
# -------------------------------------------------------------------
resource "azurerm_resource_group" "acr_rg" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

# -------------------------------------------------------------------
# Azure Container Registry
# -------------------------------------------------------------------
resource "azurerm_container_registry" "acr" {
  name                          = var.acr_name
  resource_group_name           = azurerm_resource_group.acr_rg.name
  location                      = azurerm_resource_group.acr_rg.location
  sku                           = var.sku
  admin_enabled                 = false                 # Use managed identity, never admin user
  # Note: public_network_access_enabled = false only supported on Premium SKU

  tags = var.tags
}

# -------------------------------------------------------------------
# Azure Kubernetes Service (AKS)
# -------------------------------------------------------------------
resource "azurerm_kubernetes_cluster" "aks" {
  name                = var.aks_cluster_name
  location            = azurerm_resource_group.acr_rg.location
  resource_group_name = azurerm_resource_group.acr_rg.name
  dns_prefix          = var.aks_dns_prefix

  # Restrict who can reach the Kubernetes API server
  api_server_access_profile {
    authorized_ip_ranges = var.api_server_authorized_ip_ranges
  }

  default_node_pool {
    name                        = "default"
    node_count                  = var.node_count
    vm_size                     = var.vm_size
    only_critical_addons_enabled = false
    os_disk_size_gb             = 50

    upgrade_settings {
      max_surge = "10%"
    }
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin    = "azure"
    network_policy    = "azure"          # Enable network policy for pod-level traffic control
    load_balancer_sku = "standard"
  }

  # Enable Azure Policy add-on for governance enforcement
  azure_policy_enabled = true

  # RBAC — AKS-managed Entra integration with Azure RBAC
  azure_active_directory_role_based_access_control {
    managed            = true
    azure_rbac_enabled = true
    admin_group_object_ids = var.aks_admin_group_object_ids
  }

  oidc_issuer_enabled = true

  # Disable local admin kubeconfig (force AAD auth only)
  local_account_disabled = true

  tags = var.tags
}

# -------------------------------------------------------------------
# Role Assignment: Allow AKS to pull images from ACR
# -------------------------------------------------------------------
resource "azurerm_role_assignment" "aks_acr_pull" {
  principal_id                     = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
  role_definition_name             = "AcrPull"
  scope                            = azurerm_container_registry.acr.id
  skip_service_principal_aad_check = true
}

# -------------------------------------------------------------------
# Azure Database for PostgreSQL Flexible Server
# -------------------------------------------------------------------
resource "azurerm_postgresql_flexible_server" "postgres" {
  name                   = var.postgres_server_name
  resource_group_name    = azurerm_resource_group.acr_rg.name
  location               = var.postgres_location   # eastus2 — eastus has subscription restrictions
  version                = "15"                        # Use latest supported version
  administrator_login    = var.postgres_admin_username
  administrator_password = var.postgres_admin_password
  storage_mb             = 32768
  sku_name               = "B_Standard_B1ms"
  zone                   = "3"

  # Backup retention for disaster recovery
  backup_retention_days        = 7
  geo_redundant_backup_enabled = false

  tags = var.tags
}

resource "azurerm_postgresql_flexible_server_database" "voting_db" {
  name      = var.postgres_database_name
  server_id = azurerm_postgresql_flexible_server.postgres.id
  charset   = "UTF8"
  collation = "en_US.utf8"
}

# Restrict PostgreSQL access to AKS subnet only — remove 0.0.0.0/0 rule
resource "azurerm_postgresql_flexible_server_firewall_rule" "allow_aks_subnet" {
  name             = "AllowAKSSubnet"
  server_id        = azurerm_postgresql_flexible_server.postgres.id
  start_ip_address = var.aks_outbound_ip
  end_ip_address   = var.aks_outbound_ip
}

# -------------------------------------------------------------------
# Azure Redis Cache
# -------------------------------------------------------------------
resource "azurerm_redis_cache" "redis" {
  name                = var.redis_cache_name
  location            = azurerm_resource_group.acr_rg.location
  resource_group_name = azurerm_resource_group.acr_rg.name
  capacity            = 1
  family              = "C"
  sku_name            = "Standard"             # Standard = replication + failover; Basic is single node, no SLA
  non_ssl_port_enabled = false                 # Disable plaintext port 6379
  minimum_tls_version = "1.2"

  redis_configuration {
    authentication_enabled = true               # Require AUTH password
  }

  tags = var.tags
}

# -------------------------------------------------------------------
# Post-install: run scripts after AKS is ready
# Installs kubectl config, Helm, ArgoCD automatically
# -------------------------------------------------------------------
resource "null_resource" "post_install" {
  depends_on = [azurerm_kubernetes_cluster.aks]

  triggers = {
    cluster_id = azurerm_kubernetes_cluster.aks.id
  }

  provisioner "local-exec" {
    command     = "az aks install-cli; az aks get-credentials --resource-group ${var.resource_group_name} --name ${var.aks_cluster_name} --overwrite-existing; $env:PATH += ';' + $env:USERPROFILE + '\\.azure-kubelogin'; $env:PATH += ';' + $env:USERPROFILE + '\\.azure-kubectl'; kubelogin convert-kubeconfig -l azurecli"
    interpreter = ["PowerShell", "-Command"]
  }
}
