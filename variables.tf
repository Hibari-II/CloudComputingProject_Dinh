variable "exoscale_key" {
  description = "Please enter your Exoscale API key"
  type = string
}

variable "exoscale_secret" {
  description = "Please enter your Exoscale API secrets"
  type = string
}

variable "zone" {
	default = "at-vie-1"
	type = string
}
