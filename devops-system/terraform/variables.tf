variable "aws_region" {
  description = "AWS Region"
  type        = string
  default     = "us-east-1"
}

variable "instance_type" {
  description = "EC2 Instance Type"
  type        = string
  default     = "m7i-flex.large"
}

variable "github_repo" {
  description = "GitHub Repository URL"
  type        = string
  default     = "https://github.com/mohammedmusa1/intern-devops.git"
}

variable "github_pat" {
  description = "GitHub Personal Access Token"
  type        = string
  default     = ""
  sensitive   = true
}

variable "dockerhub_username" {
  description = "DockerHub Username"
  type        = string
  default     = ""
}

variable "dockerhub_token" {
  description = "DockerHub Token"
  type        = string
  default     = ""
  sensitive   = true
}

variable "app_name" {
  description = "Application Name"
  type        = string
  default     = "my-app"
}
