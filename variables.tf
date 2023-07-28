# variables.tf
variable "project_id" {
  description = "The ID of the GCP project"
  type        = string
}

variable "region" {
  description = "The region of the GCP project"
  type        = string
}

variable "zone" {
  description = "The zone within the GCP region"
  type        = string
}

variable "bastion_image" {
  description = "The name image"
  type        = string
}
