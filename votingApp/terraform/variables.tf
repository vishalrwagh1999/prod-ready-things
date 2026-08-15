variable "subscription_id" {
  description = "Azure Subscription ID — pass via TF_VAR_subscription_id env var, never hardcode"
  type        = string
  sensitive   = true
  # No default — must be supplied at runtime
}

variable "resource_group_name" {
  description = "Resource group for all resources"
  type        = string
  default     = "voting-app-rg"
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "East US"
}

variable "acr_name" {
  description = "ACR name — globally unique, alphanumeric only, 5-50 chars"
  type        = string
  default     = "votingAppVishal"

  validation {
    condition     = can(regex("^[a-zA-Z0-9]{5,50}$", var.acr_name))
    error_message = "ACR name must be 5-50 alphanumeric characters."
  }
}

variable "sku" {
  description = "ACR pricing tier: Basic | Standard | Premium"
  type        = string
  default     = "Basic"

  validation {
    condition     = contains(["Basic", "Standard", "Premium"], var.sku)
    error_message = "SKU must be one of: Basic, Standard, Premium."
  }
}

# AAD group whose members get cluster-admin rights
variable "aks_admin_group_object_ids" {
  description = "List of AAD group object IDs that will have admin access to AKS. Get via: az ad group show --group '<name>' --query id -o tsv"
  type        = list(string)
  default     = []
}

variable "aks_cluster_name" {
  description = "Name of the AKS cluster"
  type        = string
}

variable "aks_dns_prefix" {
  description = "DNS prefix for AKS cluster"
  type        = string
}

variable "node_count" {
  description = "Number of nodes in the AKS default pool"
  type        = number
  default     = 2
}

variable "vm_size" {
  description = "VM size for AKS nodes"
  type        = string
  default     = "Standard_D2s_v3"
}

# Whitelist of CIDRs allowed to reach the Kubernetes API server
variable "api_server_authorized_ip_ranges" {
  description = "List of CIDR ranges allowed to access AKS API server. Restrict to your corporate/VPN IPs."
  type        = list(string)
  # No default — caller must supply; prevents open API server
}

variable "postgres_location" {
  description = "Region for PostgreSQL — must differ from main location if subscription restricts eastus"
  type        = string
  default     = "East US 2"
}

variable "postgres_server_name" {
  description = "Name of the PostgreSQL Flexible Server"
  type        = string
}

variable "postgres_admin_username" {
  description = "PostgreSQL administrator login"
  type        = string
  sensitive   = true
}

variable "postgres_admin_password" {
  description = "PostgreSQL administrator password"
  type        = string
  sensitive   = true
}

variable "postgres_database_name" {
  description = "Name of the PostgreSQL database"
  type        = string
  default     = "votingdb"
}

# Outbound IP of AKS nodes — used to scope PostgreSQL firewall rule
variable "aks_outbound_ip" {
  description = "Outbound public IP of AKS node pool to allow into PostgreSQL firewall"
  type        = string
}

variable "redis_cache_name" {
  description = "Name of the Redis Cache instance"
  type        = string
}

variable "tags" {
  description = "Tags applied to all resources"
  type        = map(string)
  default = {
    Project     = "VotingApp"
    Owner       = "Vishal"
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}
