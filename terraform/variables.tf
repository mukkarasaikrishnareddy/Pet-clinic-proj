variable "ecr_repository_name" {
  description = "Amazon ECR repository name"
  type        = string
  default     = "petclinic"
}

variable "eks_security_group_id" {
  description = "Security group ID used by the EKS cluster"
  type        = string
}
