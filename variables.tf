// VPC Vars

variable "vpc_id" {
  type        = string
  description = "The VPC ID that the eks cluster and nodes will be deployed to"
}

variable "vpc_private_subnets" {
  type        = list(string)
  description = "The private subnets that the eks cluster and nodes will be deployed to"
}

// AMI Vars

variable "ami_owner" {
  type        = string
  description = "The AMI owner ID used to filter which AMI to use to deploy the eks nodes"
  default     = "602401143452"
}

// AWS Vars

variable "aws_key_name" {
  type        = string
  description = "The name of the AWS key pair used to deploy the eks nodes with"
}

// EKS Vars

variable "eks_cluster_endpoint_private_access" {
  type        = bool
  description = "A boolean that determines if the EKS cluster is publicly accessible or not (true = accessible, false = not accessible)"
  default     = false
}

variable "eks_cluster_access_cidrs" {
  type        = list(string)
  description = "The CIDRs which will grant access to the eks cluster that is created"
}

variable "eks_node_instance_type" {
  type        = string
  description = "The instance type size used to deploy the eks nodes with"
  default     = "m4.large"
}

variable "eks_node_volume_size" {
  type        = number
  description = "The volume size (in GB) used to deploy the eks nodes with"
  default     = 50
}

variable "eks_node_desired_capacity" {
  type        = number
  description = "The desired capacity of eks nodes in the autoscaling group to be up at a time"
  default     = 2
}

variable "eks_node_max_size" {
  type        = number
  description = "The desired maximum number of eks nodes in the autoscaling group that can be up at a time"
  default     = 2
}

variable "eks_node_min_size" {
  type        = number
  description = "The desired minimum number of eks nodes in the autoscaling group that can be up at a time"
  default     = 2
}

// Tags

variable "default_tags" {
  type = object({
    owner       = string
    project     = string
    environment = string
    contact     = string
    ttl         = string
  })
  description = "The list of default tags to attach to resources deployed for EKS cluster"
  default     = {
    owner       = "isaacma4"
    project     = "test"
    environment = "demo"
    contact     = "isaac_ma@live.com"
    ttl         = "Forever"
  }
}

variable "tags" {
  type        = map(string)
  description = "The list of tags that merge and overwrite defaults"
  default     = {}
}
