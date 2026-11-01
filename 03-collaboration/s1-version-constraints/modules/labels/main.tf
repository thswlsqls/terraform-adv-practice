terraform {
  required_providers {
    random = {
      source  = "hashicorp/random"
      version = ">= 3.5.0"
    }
  }
}

variable "name" {
  type = string
}

resource "random_id" "this" {
  prefix      = "${var.name}-"
  byte_length = 4
}

output "id" {
  value = random_id.this.hex
}
