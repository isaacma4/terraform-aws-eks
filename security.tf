resource "aws_security_group" "eks_cluster" {
  name        = "${local.prefix}_eks_cluster_${random_id.hash.hex}"
  description = "Cluster communication with EKS worker nodes"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, map("Name", "${local.prefix}-eks-cluster-sg-${random_id.hash.hex}"))
}

resource "aws_security_group_rule" "eks_cluster_access" {
  type        = "ingress"
  from_port   = 443
  to_port     = 443
  protocol    = "tcp"
  cidr_blocks = var.eks_cluster_access_cidrs

  security_group_id = aws_security_group.eks_cluster.id
}

resource "aws_security_group" "eks_node" {
  name        = "${local.prefix}_eks_node_${random_id.hash.hex}"
  description = "Security group for all nodes in the EKS cluster"
  vpc_id      = var.vpc_id

  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    self      = true
  }

  ingress {
    from_port       = 1025
    to_port         = 65535
    protocol        = "tcp"
    security_groups = [aws_security_group.eks_cluster.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, map("Name", "${local.prefix}-eks-node-sg-${random_id.hash.hex}"))
}

resource "aws_security_group_rule" "eks_node_access_to_cluster" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.eks_node.id

  security_group_id = aws_security_group.eks_cluster.id
}
