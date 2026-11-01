variable "name" {
  type        = string
  description = "Name 태그 값"
}

variable "subnet_id" {
  type        = string
  description = "인스턴스를 배치할 서브넷"
}

variable "ami_id" {
  type        = string
  description = "AMI ID"
}

variable "instance_type" {
  type        = string
  default     = "t3.micro"
  description = "EC2 인스턴스 타입"
}

variable "sg_name_prefix" {
  type        = string
  default     = null
  description = "SG 이름 접두사. null이면 \"<name>-\" (기존 SG 이름 보존용)"
}

variable "ingress_ports" {
  type        = set(number)
  default     = [80]
  description = "0.0.0.0/0에 공개할 TCP 포트"
}
