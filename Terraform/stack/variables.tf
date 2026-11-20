variable "alert_email_to" {
  description = "Destination email address for SRE alerts"
  type        = string
  default     = "your-email@example.com"
}

variable "smtp_smarthost" {
  description = "SMTP host and port (e.g. smtp.gmail.com:587 or smtp-mail.outlook.com:587)"
  type        = string
  default     = "smtp.gmail.com:587"
}

variable "smtp_from" {
  description = "Sender email address (From header)"
  type        = string
  default     = "alerts-sre@example.com"
}

variable "smtp_auth_username" {
  description = "SMTP authentication username / sender email"
  type        = string
  default     = "your-email@example.com"
}

variable "smtp_auth_password" {
  description = "SMTP authentication password or App Password"
  type        = string
  sensitive   = true
  default     = "your-app-password"
}
