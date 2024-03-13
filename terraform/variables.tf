variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

variable "clusterName" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "vprofile-eks"
}
