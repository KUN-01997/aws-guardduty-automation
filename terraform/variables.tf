variable "aws_region" {
  description = "AWS region to deploy to"
  type        = string
  default     = "us-east-1"
}

variable "alert_email" {
  description = "Email address to subscribe to SNS alerts"
  type        = string
}
