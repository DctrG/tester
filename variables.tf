variable "project_id" {
  type        = string
  description = "The GCP project ID"
}

variable "region" {
  type        = string
  description = "GCP region"
}

variable "zone" {
  type        = string
  description = "GCP zone within the region"
}

variable "vpc_name" {
  type        = string
  description = "The name of the VPC"
}

variable "subnet_name" {
  type        = string
  description = "The name of the subnet"
}

variable "vm_name" {
  type        = string
  description = "The name of the VM"
}

variable "vm_username" {
  type        = string
  description = "The username for the VM"
}

variable "api_key" {
  type        = string
  description = "AIRS API Key"
}

variable "profile_name" {
  type        = string
  description = "AIRS Profile name"
}

variable "git_repo_url" {
  type        = string
  description = "The repo"
}