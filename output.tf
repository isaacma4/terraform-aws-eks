output "eks_cluster_endpoint" {
  value = "${aws_eks_cluster.eks_cluster.endpoint}"
}

output "eks_cluster_ca_certificate" {
  value = "${base64decode(aws_eks_cluster.eks_cluster.certificate_authority.0.data)}"
}

output "eks_cluster_token" {
  value     = "${data.external.aws_iam_authenticator.result.token}"
  sensitive = true
}

output "eks_kubeconfig" {
  value = "${data.template_file.kubeconfig.rendered}"
}