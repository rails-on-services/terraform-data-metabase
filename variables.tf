variable "backend_host" {
  type        = string
  default     = ""
  description = "[Required] Backend host"
}

variable "backend_user" {
  type        = string
  default     = ""
  description = "[Required] Backend user to authenticate"
}

variable "backend_password" {
  type        = string
  default     = ""
  description = "[Required] Backend password to authenticate"
}

variable "backend_account_id" {
  type        = string
  default     = ""
  description = "[Required] Backend account_id to authenticate"
}

variable "metabase_host" {
  type        = string
  default     = ""
  description = "[Required] Metabase host"
}

variable "metabase_username" {
  type        = string
  default     = ""
  description = "[Required] Metabase username"
}

variable "metabase_password" {
  type        = string
  default     = ""
  description = "[Required] Metabase paswword"
}

variable "metabase_database_id" {
  type        = string
  default     = ""
  description = "[Required] Metabase card database_id for given environment"
}

variable "metabase_profile" {
  type        = string
  default     = ""
  description = "[Required] Environment profile"
}

variable "metabase_feature_set" {
  type        = string
  default     = ""
  description = "[Optional] Environment feature set"
}