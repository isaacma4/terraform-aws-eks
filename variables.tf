// VPC Vars

variable "vpc_id" {
  description = "The VPC ID that the eks cluster and nodes will be deployed to"
}

variable "vpc_private_subnets" {
  description = "The private subnets that the eks cluster and nodes will be deployed to"
  type        = list(string)
}

// AMI Vars

variable "ami_owner" {
  description = "The AMI owner ID used to filter which AMI to use to deploy the eks nodes"
  default     = "602401143452"
}

// AWS Vars

variable "aws_region" {
  description = "The AWS region to deploy resources to"
  default     = "us-east-1"
}

variable "aws_key_name" {
  description = "The name of the AWS key pair used to deploy the eks nodes with"
}

// EKS Vars

variable "eks_cluster_endpoint_private_access" {
  description = "A boolean that determines if the EKS cluster is publicly accessible or not (true = accessible, false = not accessible)"
  default     = false
}

variable "eks_cluster_access_cidrs" {
  description = "The CIDRs which will grant access to the eks cluster that is created"
  type        = list(string)
}

variable "eks_node_instance_type" {
  description = "The instance type size used to deploy the eks nodes with"
}

variable "eks_node_volume_size" {
  description = "The volume size (in GB) used to deploy the eks nodes with"
}

variable "eks_node_desired_capacity" {
  description = "The desired capacity of eks nodes in the autoscaling group to be up at a time"
}

variable "eks_node_max_size" {
  description = "The desired maximum number of eks nodes in the autoscaling group that can be up at a time"
}

variable "eks_node_min_size" {
  description = "The desired minimum number of eks nodes in the autoscaling group that can be up at a time"
}

// Tags

variable "tag_customer" {
  description = "The customer that this project is being developed and deployed for"
  default     = "isaacma"
}

variable "tag_project_name" {
  description = "The name of the project that these resources are being developed and deployed for"
}

variable "tag_environment" {
  description = "The environment that the resources are being deployed for"
}

variable "tag_contact" {
  description = "The contact for support for development and deployment of these resources"
  default     = "isaac_ma@live.com"
}

variable "tag_ttl" {
  description = "The TTL of the components of the resources deployed"
  default     = "Forever"
}
