variable "env" {
  type    = string
  default = "dev"
}

variable "vpc_cidr" {
  type    = string
  default = "10.20.0.0/16"
}

variable "default_tags" {
  type    = map(string)
  default = { Team = "platform", Env = "unknown" }
}

variable "instance_type_by_env" {
  type    = map(string)
  default = { prod = "t3.small" }
}

variable "egress" {
  type = list(object({
    port        = number
    cidr_blocks = list(string)
    description = optional(string, "managed by terraform")
  }))
  default = [
    { port = 443, cidr_blocks = ["0.0.0.0/0"] },
    { port = 5432, cidr_blocks = ["10.20.0.0/16"], description = "postgres" },
  ]
}

# TODO: locals, aws_security_group(+dynamic egress), aws_vpc_security_group_ingress_rule(for_each), outputs
