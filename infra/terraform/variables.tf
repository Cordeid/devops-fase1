variable "aws_region" {
  description = "Região da AWS (o AWS Academy Learner Lab só permite us-east-1 e us-west-2)"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Nome usado como prefixo dos recursos"
  type        = string
  default     = "devops-fase1"
}

variable "instance_type" {
  description = "Tipo da instância EC2"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "Par de chaves SSH já existente (no Learner Lab, o padrão é vockey)"
  type        = string
  default     = "vockey"
}

variable "repo_url" {
  description = "URL pública do repositório GitHub com a aplicação"
  type        = string
}

variable "allowed_ssh_cidr" {
  description = "Faixa de IP liberada para SSH (ideal: seu IP/32)"
  type        = string
  default     = "0.0.0.0/0"
}
