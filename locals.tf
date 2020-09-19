locals {
  tags   = merge(var.default_tags, var.tags)
  prefix = "${local.tags.project}-${local.tags.environment}"

  # For k8s
  common_tags = "${map(
    "X-Project", "${local.tags.project}",
    "X-Contact", "${local.tags.contact}",
    "X-TTL", "${local.tags.ttl}",
    "kubernetes.io/cluster/${local.prefix}-eks-cluster", "owned")}"
}