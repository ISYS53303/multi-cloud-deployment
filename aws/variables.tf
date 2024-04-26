variable "instance_type" {
  description = "Type of instance to deploy"
  default     = "t2.micro"
}

variable "ami_id" {
  description = "ID of the AMI to deploy"
  default     = "ami-04e5276ebb8451442"
}
