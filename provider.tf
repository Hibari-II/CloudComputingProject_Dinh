terraform {
	required_providers {
		exoscale = {
			source = "terraform-providers/exoscale"
		}
	}
}

provider "exoscale" {
  key = var.exoscale_key
  secret = var.exoscale_secret
}
