# variables.tf

variable "aws_region" {
  description = "AWS region for the resources"
  type        = string
  default     = "eu-west-1"
}

variable "function_name" {
  description = "Name of the Lambda function"
  type        = string
  default     = "ApiConsumerFunction"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "Development"
}

