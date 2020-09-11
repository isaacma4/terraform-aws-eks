provider "aws" {
  region = var.aws_region
}

resource "random_id" "hash" {
  byte_length = 4
}

resource "aws_iam_role" "eks_cluster_role" {
  name               = "${var.tag_project_name}-${var.tag_environment}-eks-cluster-role"
  path               = "/"
  assume_role_policy = file("${path.module}/templates/aws_eks_assume_role_policy.json")
}

resource "aws_iam_role_policy_attachment" "eks_cluster_AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster_role.name
}

resource "aws_iam_role_policy_attachment" "eks_cluster_AmazonEKSServicePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = aws_iam_role.eks_cluster_role.name
}

resource "aws_eks_cluster" "eks_cluster" {
  name     = "${var.tag_project_name}-${var.tag_environment}-eks-cluster"
  role_arn = aws_iam_role.eks_cluster_role.arn

  vpc_config {
    security_group_ids      = [aws_security_group.eks_cluster.id]
    subnet_ids              = var.vpc_private_subnets
    endpoint_private_access = var.eks_cluster_endpoint_private_access
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.eks_cluster_AmazonEKSServicePolicy,
  ]
}

resource "aws_iam_role" "eks_node_role" {
  name               = "${var.tag_project_name}-${var.tag_environment}-eks-node-role"
  path               = "/"
  assume_role_policy = file("${path.module}/templates/aws_ec2_assume_role_policy.json")
}

resource "aws_iam_role_policy_attachment" "eks_node_AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_node_role.name
}

resource "aws_iam_role_policy_attachment" "eks_node_AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_node_role.name
}

resource "aws_iam_role_policy_attachment" "eks_node_AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_node_role.name
}

resource "aws_iam_instance_profile" "eks_node" {
  name = "${var.tag_project_name}-${var.tag_environment}-eks-node-instance-profile"
  role = aws_iam_role.eks_node_role.name
}

data "aws_ami" "eks_node" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amazon-eks-node-${aws_eks_cluster.eks_cluster.version}-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = [var.ami_owner]
}

resource "aws_launch_configuration" "eks_node_lc" {
  iam_instance_profile        = aws_iam_instance_profile.eks_node.name
  image_id                    = data.aws_ami.eks_node.id
  key_name                    = var.aws_key_name
  instance_type               = var.eks_node_instance_type
  name_prefix                 = "${var.tag_project_name}-${var.tag_environment}-eks-node-lc-${random_id.hash.hex}"
  security_groups             = [aws_security_group.eks_node.id]
  user_data                   = <<USERDATA
#!/bin/bash -xe
/etc/eks/bootstrap.sh ${aws_eks_cluster.eks_cluster.name}
USERDATA

  root_block_device {
    delete_on_termination = true
    volume_size           = var.eks_node_volume_size
    volume_type           = "gp2"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "eks_node_asg" {
  name                 = "${var.tag_project_name}-${var.tag_environment}-eks-node-asg-${random_id.hash.hex}"
  desired_capacity     = var.eks_node_desired_capacity
  launch_configuration = aws_launch_configuration.eks_node_lc.id
  max_size             = var.eks_node_max_size
  min_size             = var.eks_node_min_size
  vpc_zone_identifier  = var.vpc_private_subnets

  tags = [
    {
      key                 = "Name"
      value               = "${format("%s-%s-%s-%s", var.tag_project_name, var.tag_environment, "eks-node", random_id.hash.hex)}"
      propagate_at_launch = true
    },
    {
      key                 = "X-Project"
      value               = "${var.tag_project_name}"
      propagate_at_launch = true
    },
    {
      key                 = "X-Contact"
      value               = "${var.tag_contact}"
      propagate_at_launch = true
    },
    {
      key                 = "X-TTL"
      value               = "${var.tag_ttl}"
      propagate_at_launch = true
    },
    {
      key                 = "kubernetes.io/cluster/${aws_eks_cluster.eks_cluster.name}"
      value               = "owned"
      propagate_at_launch = true 
    }
  ]

  lifecycle {
    create_before_destroy = true
  }
}

# Note: Must have aws-iam-authenticator and jq installed locally to have this terraform data source to work
data "external" "aws_iam_authenticator" {
  program = ["sh", "-c", "aws-iam-authenticator token -i ${aws_eks_cluster.eks_cluster.name} | jq -r -c .status"]
}
 
provider "kubernetes" {
  host                   = aws_eks_cluster.eks_cluster.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.eks_cluster.certificate_authority.0.data)
  token                  = data.external.aws_iam_authenticator.result.token
  load_config_file       = false
  version                = "~> 1.5"
}

resource "kubernetes_config_map" "aws_auth" {
  metadata {
    name = "aws-auth"
    namespace = "kube-system"
  }

  data = {
    mapRoles = <<EOF
- rolearn: ${aws_iam_role.eks_node_role.arn}
  username: system:node:{{EC2PrivateDNSName}}
  groups:
    - system:bootstrappers
    - system:nodes
EOF
  }

  depends_on = [
    aws_eks_cluster.eks_cluster
  ]
}

data "template_file" "kubeconfig" {
  template = <<KUBECONFIG

apiVersion: v1
clusters:
- cluster:
    server: $${eks_cluster_endpoint}
    certificate-authority-data: $${eks_cluster_cert_auth}
  name: kubernetes
contexts:
- context:
    cluster: kubernetes
    user: aws
  name: aws
current-context: aws
kind: Config
preferences: {}
users:
- name: aws
  user:
    exec:
      apiVersion: client.authentication.k8s.io/v1alpha1
      command: aws-iam-authenticator
      args:
      - "token"
      - "-i"
      - "$${eks_cluster_name}"
KUBECONFIG

  vars = {
    eks_cluster_endpoint  = aws_eks_cluster.eks_cluster.endpoint
    eks_cluster_cert_auth = aws_eks_cluster.eks_cluster.certificate_authority.0.data
    eks_cluster_name      = aws_eks_cluster.eks_cluster.name
  }
}